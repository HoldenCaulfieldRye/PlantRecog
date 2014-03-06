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

// Re-Try Timer
@property (strong, nonatomic) NSTimer *networkIntervalTimer;

// Upload Flags
@property (nonatomic) BOOL uploadQueueProcessingActive;
@property (nonatomic) BOOL uploadQueueHalted;

// Update Flags And Current Queue
@property (strong, nonatomic) NSArray *specimenForUpdating;
@property (nonatomic) BOOL updateQueueProcessingActive;
@property (nonatomic) BOOL updateQueueHalted;

@end

@implementation BLEFServerInterface


- (id)init
{
    self = [super init];
    if (self){
        // Upload Queue
        _uploadQueueProcessingActive = false;
        _uploadQueueHalted = false;
        
        // Update Queue
        _updateQueueProcessingActive = false;
        _updateQueueHalted = true;
        
        // Database
        _database = [[BLEFDatabase alloc] init];
        [_database setManagedObjectContext:nil];
        
        // Network Session
        _updateSession = [NSURLSession sharedSession];

        _boundary = @"---------------------------14737809831466499882746641449";
        
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
            _uploadQueueProcessingActive = true;
        } else {
            return false;
        }
    }
    BLEFObservation * observation = [self nextInUploadQueue];
    if (observation != nil){
        NSURLSessionUploadTask *task = [self createUploadTaskForObservation:observation completion:^(BOOL success) {
            _uploadQueueProcessingActive = false;
            NSLog(@"Upload Result:%hhd", success);
            if (success){
                [_database saveChanges];
                [self processUploads];
            } else {
                [self uploadErrorWaitAndRetry];
            }
        }];
        if (task != nil){
            [task resume];
            return true;
        }
    }
    _uploadQueueProcessingActive = false;
    return false;
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

- (void) uploadErrorWaitAndRetry
{
    _updateQueueHalted = true;
    [self performSelector:@selector(reStartUploadProcessing) withObject:nil afterDelay:30.0];
}

#pragma mark Update Pool Methods

- (BOOL) processUpdates
{
    @synchronized(self){
        if (!_updateQueueHalted && !_updateQueueProcessingActive){
            _updateQueueProcessingActive = true;
        } else {
            return false;
        }
    }
    _specimenForUpdating = [_database getSpecimenNeedingUpdate];
    return [self processUpdateIndex:0];
}

- (BOOL) processUpdateIndex:(NSInteger)index {
    if (_specimenForUpdating != nil && !_updateQueueHalted){
        if (index < [_specimenForUpdating count]){
            BLEFSpecimen *specimen = (BLEFSpecimen *)[_specimenForUpdating objectAtIndex:index];
            if (specimen != nil){
                NSURLSessionDataTask *task = [self createUpdateTaskForSpecimen:specimen completion:^(BOOL updated) {
                    if (updated){
                        [_database saveChanges];
                    }
                    [self processUpdateIndex:index+1];
                }];
                if (task != nil){
                    [task resume];
                    return true;
                }
            }
        }
    }
    _updateQueueProcessingActive = false;
    return false;
}

- (BOOL) reStartUpdateProccessing
{
    if (_updateQueueHalted){
        _updateQueueHalted = false;
        _networkIntervalTimer = [NSTimer timerWithTimeInterval:15.0 target:self selector:@selector(networkRetry:) userInfo:nil repeats:YES];
        if (_networkIntervalTimer != nil){
            [[NSRunLoop mainRunLoop] addTimer:_networkIntervalTimer forMode:NSRunLoopCommonModes];
            return true;
        }
    }
    return false;
}

- (void)networkRetry:(NSTimer*)timer
{
    [self processUpdates];
}

- (BOOL)stopUpdateProcessing
{
    _updateQueueHalted = true;
    [_networkIntervalTimer invalidate];
    _networkIntervalTimer = nil;
    return true;
}


#pragma mark Server Interface Methods

- (NSURLSessionUploadTask *)createUploadTaskForObservation:(BLEFObservation *)observation completion:(void (^)(BOOL success))handler
{
    if ((observation != nil) && ([observation isKindOfClass:[BLEFObservation class]])){
        NSManagedObjectID *observationID = [observation objectID];
        NSData *imageData = [observation getImageData];
        NSDictionary *params = @{@"segment": ([observation segment] != nil ? [observation segment] : @"0"),
                                 @"group_id": ([[observation specimen] groupid]? [[observation specimen] groupid] : @"0"),
                                 @"latitude": [NSNumber numberWithDouble:[[observation specimen] latitude]],
                                 @"longitude": [NSNumber numberWithDouble:[[observation specimen] longitude]]
                                 };
        if (imageData != nil && params != nil){
            NSData *bodyData = [self createUploadBodyDataWithFields:params andFileData:imageData];
            NSURLRequest *request = [self createUploadRequestForObservation:observation];
            NSURLSessionConfiguration *uploadConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            uploadConfig.HTTPAdditionalHeaders = @{
                                                   @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", _boundary]
                                                   };
            _uploadSession = [NSURLSession sessionWithConfiguration:uploadConfig];
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
                BLEFResult *result = [_database addNewResultToSpecimen:specimen];
                [result setName:classification];
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
        NSString *groupID = json[@"group_id"];
        NSLog(@"GroupID received: %@", groupID);
        if ((groupID != nil) && ([groupID length] > 2)){
            BLEFObservation *observation = (BLEFObservation *)[_database fetchObjectWithID:observationID];
            if (observation != NULL){
                if ([[observation specimen] groupid] == nil){
                    [[observation specimen] setGroupid:groupID];
                }
                [observation setUploaded:true];
                return true;
            }
        }
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
    NSString *urlAsString = [NSString stringWithFormat:@"http://192.168.1.78:5000/job/%@/", [specimen groupid]];
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
