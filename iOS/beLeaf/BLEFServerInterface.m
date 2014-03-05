//
//  BLEFServerInterface.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFServerInterface.h"
#import "BLEFDatabase.h"
#import "BLEFObservation.h"

@interface BLEFServerInterface ()

// Database Interface
@property (strong, nonatomic) BLEFDatabase * database;

// Network Session
@property (strong, nonatomic) NSURLSession * updateSession;
@property (strong, nonatomic) NSURLSession * uploadSession;
@property (strong, nonatomic) NSString * boundary;

// Upload Flags
@property (nonatomic) BOOL uploadQueueProcessingActive;
@property (nonatomic) BOOL uploadQueueHalted;


// Update Pollers
@property (strong, nonatomic) NSOperationQueue *pollers;

@end

@implementation BLEFServerInterface


- (id)init
{
    self = [super init];
    if (self){
        // Upload Queue
        _uploadQueueProcessingActive = false;
        _uploadQueueHalted = false;
        
        // Update Pollers
        _pollers = [[NSOperationQueue alloc] init];
        [_pollers setMaxConcurrentOperationCount:1];
        
        // Database
        _database = [[BLEFDatabase alloc] init];
        [_database setManagedObjectContext:nil];
        
        // Network Session
        _updateSession = [NSURLSession sharedSession];

        NSURLSessionConfiguration *uploadConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        _boundary = @"---------------------------14737809831466499882746641449";
        uploadConfig.HTTPAdditionalHeaders = @{
                                               @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", _boundary]
                                               };
        _uploadSession = [NSURLSession sessionWithConfiguration:uploadConfig];
        
        // Subscribe to notifications
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(databaseUpdateNotification:)
                       name:BLEFDatabaseUpdateNotification object:_database];
        [center addObserver:self selector:@selector(reStartUploadProcessing)
                       name:BLEFNetworkRetryNotification object:nil];
    }
    return self;
}

#pragma mark - PUBLIC

#pragma mark Database Methods

- (void) setContext:(NSManagedObjectContext*)context
{
    [_database setManagedObjectContext:context];
}

#pragma mark Upload Queue Methods

- (BOOL) processUploads
{
    @synchronized(self){
    if (!_uploadQueueHalted && !_uploadQueueProcessingActive){
        BLEFObservation * observation = [self nextInUploadQueue];
        if (observation != nil){
            NSURLSessionUploadTask *task = [self createUploadTaskForObservation:observation completion:^(BOOL success) {
                _uploadQueueProcessingActive = false;
                if (success){
                    [self processUploads];
                    [self processUpdates];
                } else {
                    _uploadQueueHalted = true;
                }
            }];
            if (task != nil){
                [task resume];
                _uploadQueueProcessingActive = true;
            }
            return true;
        }
    }
    return false;
    }
}

- (BOOL) reStartUploadProcessing
{
    _uploadQueueHalted = false;
    [self processUploads];
    return true;
}

- (BOOL) stopUploadProcessing;
{
    _uploadQueueHalted = true;
    return true;
}

#pragma mark Update Pool Methods

- (BOOL) processUpdates
{
    NSArray *specimenForUpdating = [_database getSpecimenNeedingUpdate];
    if (specimenForUpdating != nil){
        for (BLEFSpecimen * specimen in specimenForUpdating) {
            [self addSpecimenToUpdatePool:specimen];
        }
    }
    return false;
}

- (BOOL) addSpecimenToUpdatePool:(BLEFSpecimen *)specimen;
{
    @synchronized(self){
        if (!specimen || [specimen updatePolling]){
            return false;
        }
        [specimen setUpdatePolling:true];
    }
    NSManagedObjectID *specimenID = [specimen objectID];
    [_pollers addOperationWithBlock:^{
        __block BOOL fin = false;
        while (!fin){
            sleep(1000);
            dispatch_async(dispatch_get_main_queue(), ^{
                BLEFSpecimen *specimen = (BLEFSpecimen *)[_database fetchObjectWithID:specimenID];
                if (specimen != nil){
                    NSURLSessionDataTask* task = [self createUpdateTaskForSpecimen:specimen completion:^(BOOL updated) {
                        if (updated){
                            fin = true;
                        }
                    }];
                    if (task != nil){
                        [task resume];
                    } else {
                        fin = true;
                    }
                }
            });
        }
    }];
    return true;
}

- (void) startPollers;
{
    return;
}

- (void) stopPollers
{
    [_pollers cancelAllOperations];
}


#pragma mark Server Interface Methods

- (NSURLSessionUploadTask *)createUploadTaskForObservation:(BLEFObservation *)observation completion:(void (^)(BOOL success))handler
{
    if ((observation != nil) && ([observation isKindOfClass:[BLEFObservation class]])){
        NSManagedObjectID *observationID = [observation objectID];
        NSData *imageData = [observation getImageData];
        NSDictionary *params = @{@"segment": ([observation segment] != nil ? [observation segment] : @"na"),
                                 @"groupid": ([[observation specimen] groupid]? [[observation specimen] groupid] : @"na"),
                                 @"latitude": [NSNumber numberWithDouble:[[observation specimen] latitude]],
                                 @"longitude": [NSNumber numberWithDouble:[[observation specimen] longitude]]
                                 };
        if (imageData != nil && params != nil){
            NSData *bodyData = [self createUploadBodyDataWithFields:params andFileData:imageData];
            NSURLRequest *request = [self createUploadRequestForObservation:observation];
            NSURLSessionUploadTask *task = [_uploadSession uploadTaskWithRequest:request
                                                                         fromData:bodyData
                                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                    BOOL _success = [self updateObservation:observationID usingData:data andError:error];
                                                                    if (handler){
                                                                        handler(_success);
                                                                    }
                                                                }];
            return task;
        }
    }
    return nil;
}

- (NSURLSessionDataTask *)createUpdateTaskForSpecimen:(BLEFSpecimen *)specimen completion:(void (^)(BOOL updated))handler
{
    if ((specimen != nil) && ([specimen isKindOfClass:[BLEFSpecimen class]])){
        NSManagedObjectID *specimenID = [specimen objectID];
        NSURLRequest *updateRequest = [self createUpdateRequestForSpecimen:specimen];
        NSURLSessionDataTask *task = [_updateSession dataTaskWithRequest:updateRequest
                                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                            BOOL _updated = [self updateSpecimen:specimenID usingData:data andError:error];
                                                            if (handler){
                                                                handler(_updated);
                                                            }
                                                        }];
        return task;
    }
    return nil;
}

#pragma mark - PRIVATE

NSString * const BLEFUploadDidSendDataNotification = @"BLEFUploadDidSendDataNotification";
NSString * const BLEFJobDidReceiveDataNotification = @"BLEFJobDidReceiveDataNotification";
NSString * const BLEFNetworkResultNotification = @"BLEFNetworkResultNotification";
NSString * const BLEFDatabaseUpdateNotification = @"BLEFDatabaseUpdateNotification";
NSString * const BLEFNetworkRetryNotification = @"BLEFNetworkRetryNotification";

#pragma mark Notifications Methods

- (void) databaseUpdateNotification:(NSNotification *)notification
{
    [self processUploads];
}

#pragma mark Upload Queue
- (BLEFObservation *) nextInUploadQueue
{
    NSArray *uploadQueue = [_database getObservationsNeedingUploading];
    if (uploadQueue != nil){
        id fetchedObject = [uploadQueue firstObject];
        if (fetchedObject != nil && [fetchedObject isKindOfClass:[BLEFObservation class]]){
            return (BLEFObservation *)fetchedObject;
        }
    }
    return nil;
}

#pragma mark Update Handlers
- (BOOL) updateSpecimen:(NSManagedObjectID *)specimenID usingData:(NSData *)data andError:(NSError *)error;
{
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if (json){
        NSString *classification = json[@"classification"];
        if ((classification != nil) && ([classification length] > 2)){
            BLEFSpecimen *specimen = (BLEFSpecimen *)[_database fetchObjectWithID:specimenID];
            if (specimen != nil){
                #warning TODO: create result and add to specimen
                return true;
            }
        }
    }
    return false;
}

- (BOOL) updateObservation:(NSManagedObjectID *)observationID usingData:(NSData *)data andError:(NSError *)error;
{
    if (error == nil){
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
        NSString *groupID = json[@"groupID"];
    
        if ((groupID != nil) && ([groupID length] > 2)){
            BLEFObservation *observation = (BLEFObservation *)[_database fetchObjectWithID:observationID];
            if (observation != NULL){
                if ([[observation specimen] groupid] == nil){
                    [[observation specimen] setGroupid:groupID];
                }
                [observation setUploaded:true];
            }
        }
        return true;
    }
    return false;
}

#pragma mark UrlConnection Creations

- (NSData *)createUploadBodyDataWithFields:(NSDictionary *)parameters andFileData:(NSData *)fileData
{
    NSMutableData *body = [NSMutableData data];
    if (parameters){
        [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", _boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding]];
        }];
    }
    
    if (fileData){
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", _boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"datafile\"; filename=\"test.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:fileData]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", _boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    return [NSData dataWithData:body];
}

#pragma mark Connection Methods

- (NSURLRequest *)createUploadRequestForObservation:(BLEFObservation *)observation
{
    //NSURL *url = [NSURL URLWithString:@"http://plantrecogniser.no-ip.biz:55580/upload"];
    NSURL *url = [NSURL URLWithString:@"http://192.168.1.78:5000/upload"];
    //NSURL *url = [NSURL URLWithString:@"http://www.hashemian.com/tools/form-post-tester.php/beLeaf999"];
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url];
    [mutableRequest setHTTPMethod:@"POST"];
    return (NSURLRequest *)mutableRequest;
}

- (NSURLRequest *)createUpdateRequestForSpecimen:(BLEFSpecimen *)specimen
{
    //NSString *urlAsString = [@"http://plantrecogniser.no-ip.biz:55580/job/" stringByAppendingString:[specimen groupid]];
    NSString *urlAsString = [@"http://192.168.1.78:5000/job/" stringByAppendingString:[specimen groupid]];
    NSURL *url = [NSURL URLWithString:urlAsString];
    return [NSURLRequest requestWithURL:url];
}
/*
  URLSession:task:didSendBodyData:totalBytesSent:totalBytesExpectedToSend:
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    BLEFServerConnection *serverConnection = (BLEFServerConnection *)connection;
    if (serverConnection.upload){
        CGFloat dataSent = totalBytesWritten;
        CGFloat dataTotal = totalBytesExpectedToWrite;
        NSNumber *progress = [NSNumber numberWithFloat: round((dataSent/dataTotal) * 10)/10];
        
        if ([progress floatValue] > [serverConnection progress]) {
            NSLog(@"Upload Progress: %@", progress);
            NSDictionary *uploadInfo = @{
                                         @"percentage" : progress,
                                        @"objectID"   : [serverConnection objID]
                                        };
            [[NSNotificationCenter defaultCenter] postNotificationName:BLEFUploadDidSendDataNotification object:nil userInfo:uploadInfo];
            [serverConnection setProgress:[progress floatValue]];
        }
    }
}
*/
@end
