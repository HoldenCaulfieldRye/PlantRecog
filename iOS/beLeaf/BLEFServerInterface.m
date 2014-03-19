//
//  BLEFServerInterface.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFServerInterface.h"
#import "BLEFObservation.h"

NSString * boundary = @"---------------------------14737809831466499882746641449";

@interface BLEFServerInterface ()

// Network Session
@property (strong, nonatomic) NSURLSession * updateSession;
@property (strong, nonatomic) NSURLSession * uploadSession;
@property (strong, nonatomic) NSURLSession * completionSession;

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
        NSURLSessionConfiguration *completionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        completionConfig.HTTPAdditionalHeaders = @{
                                               @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
                                               };
        [self setCompletionSession:[NSURLSession sessionWithConfiguration:completionConfig]];
        
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
        if (![self uploadQueueHalted] && ![self uploadQueueProcessingActive]){
            _uploadQueueProcessingActive = true;
        } else {
            return false;
        }
    }
    BLEFObservation * observation = [self nextInUploadQueue];
    if (observation != nil){
        NSURLSessionUploadTask *task = [self createUploadTaskForObservation:observation completion:^(BOOL success) {[self uploadCompletion:success];}];
        if (task != nil){
            [task resume];
            return true;
        }
    }
    _uploadQueueProcessingActive = false;
    return false;
}

- (void) uploadCompletion:(BOOL) success
{
    _uploadQueueProcessingActive = false;
    NSLog(@"Upload %@", (success == true ? @"Success" : @"Fail"));
    if (success){
        [_database saveChanges];
        [self processUploads];
    } else {
        [self uploadErrorWaitAndRetry];
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

- (void) uploadErrorWaitAndRetry
{
    _updateQueueHalted = true;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self performSelector:@selector(reStartUploadProcessing) withObject:nil afterDelay:10.0];
    });
}

#pragma mark Update Pool Methods

- (BOOL) processUpdates
{
    @synchronized(self){
        if (![self updateQueueHalted] && ![self updateQueueProcessingActive]){
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
        if (index < [[self specimenForUpdating] count]){
            BLEFSpecimen *specimen = (BLEFSpecimen *)[_specimenForUpdating objectAtIndex:index];
            if (specimen != nil){
                if ([specimen notified]){
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
                } else {
                    NSURLSessionDataTask *task = [self createCompletionTaskForSpecimen:specimen completion:^(BOOL success) {
                        [_database saveChanges];
                        [self processUpdateIndex:index+1];
                    }];
                    if (task != nil){
                        [task resume];
                        return true;
                    }
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
        [self setNetworkIntervalTimer:[NSTimer timerWithTimeInterval:10.0 target:self selector:@selector(networkRetry:) userInfo:nil repeats:YES]];
        if ([self networkIntervalTimer] != nil){
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
    [[self networkIntervalTimer] invalidate];
    [self setNetworkIntervalTimer: nil];
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
            NSData *bodyData = [self createHTTPBodyDataWithFields:params andFileData:imageData];
            NSURLRequest *request = [self createUploadRequestForObservation:observation];
            NSURLSessionConfiguration *uploadConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
            uploadConfig.HTTPAdditionalHeaders = @{
                                                   @"Content-Type"  : [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary]
                                                   };
            [self setUploadSession:[NSURLSession sessionWithConfiguration:uploadConfig]];
            NSURLSessionUploadTask *task = [[self uploadSession] uploadTaskWithRequest:request
                                                                         fromData:bodyData
                                                                completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                    BOOL _success = [self updateObservation:observationID usingData:data andError:error];
                                                                    if (handler){handler(_success);}
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
 
        void (^updateCompletion)(NSData*, NSURLResponse*, NSError*) =
            ^(NSData *data, NSURLResponse *response, NSError *error) {
                BOOL _updated = [self updateSpecimen:specimenID usingData:data andError:error];
                if (handler){
                    handler(_updated);
                }
            };
        
        NSURLSessionDataTask *task = [[self updateSession] dataTaskWithRequest:updateRequest
                                                       completionHandler:updateCompletion];
        return task;
    }
    return nil;
}

- (NSURLSessionDataTask *)createCompletionTaskForSpecimen:(BLEFSpecimen *)specimen completion:(void (^)(BOOL success))handler
{
    if ((specimen != nil) && ([specimen isKindOfClass:[BLEFSpecimen class]])){
        NSManagedObjectID *specimenID = [specimen objectID];

        NSURLRequest *completionNotification = [self createCompletionNotificationForSpecimen:specimen];
        
        void (^completionHandler)(NSData*, NSURLResponse*, NSError*) =
        ^(NSData *data, NSURLResponse *response, NSError *error) {
            BOOL _updated = [self processNotificationForSpecimen:specimenID usingData:data andError:error];
            if (handler){
                handler(_updated);
            }
        };
        
        NSURLSessionDataTask *task = [[self completionSession] dataTaskWithRequest:completionNotification
                                                             completionHandler:completionHandler];
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
    NSDictionary *classification;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if (json){
        classification = json[@"classification"];
    }
    if (classification){
        BLEFSpecimen *specimen = (BLEFSpecimen *)[_database fetchObjectWithID:specimenID];
        if (specimen != nil){
            [classification enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
                NSLog(@"%@ : %@", key, value);
                BLEFResult *result = [_database addNewResultToSpecimen:specimen];
                [result setName:key];
                [result setConfidence:[value floatValue]];
                NSLog(@"Confidence: %f", [result confidence]);
            }];
            return true;
        }
    }
    return false;
}

- (BOOL) processNotificationForSpecimen:(NSManagedObjectID *)specimenID usingData:(NSData *)data andError:(NSError *)error;
{
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if (json){
        NSString *status = json[@"updated"];
        if ((status != nil) && ([status isEqualToString:@"true"])){
            BLEFSpecimen *specimen = (BLEFSpecimen *)[_database fetchObjectWithID:specimenID];
            if (specimen != nil){
                [specimen setNotified:true];
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

- (NSData *)createHTTPBodyDataWithFields:(NSDictionary *)parameters andFileData:(NSData *)fileData
{
    NSMutableData *body = [NSMutableData data];
    if (parameters){
        [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
            [body appendData:[[NSString stringWithFormat:@"%@", value] dataUsingEncoding:NSUTF8StringEncoding]];
        }];
    }
    
    if (fileData){
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"datafile\"; filename=\"image.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:fileData]];
    }
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    return [NSData dataWithData:body];
}

#pragma mark Connection Methods

- (NSURLRequest *)createUploadRequestForObservation:(BLEFObservation *)observation
{
    NSString *serverURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"serverURL"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/upload", serverURL]];
    //NSURL *url = [NSURL URLWithString:@"http://192.168.1.78:5000/upload"];
    //NSURL *url = [NSURL URLWithString:@"http://www.hashemian.com/tools/form-post-tester.php/beLeaf999"];
    NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url];
    [mutableRequest setHTTPMethod:@"POST"];
    return (NSURLRequest *)mutableRequest;
}

- (NSURLRequest *)createUpdateRequestForSpecimen:(BLEFSpecimen *)specimen
{
    //NSString *urlAsString = [NSString stringWithFormat:@"http://192.168.1.78:5000/job/%@/", [specimen groupid]];
    NSString *serverURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"serverURL"];
    NSString *urlAsString = [NSString stringWithFormat:@"%@/job/%@", serverURL, [specimen groupid]];
    NSURL *url = [NSURL URLWithString:urlAsString];
    return [NSURLRequest requestWithURL:url];
}

- (NSURLRequest *)createCompletionNotificationForSpecimen:(BLEFSpecimen *)specimen
{
    if ([specimen groupid] != nil && [[specimen groupid] length] > 2){
        NSString *serverURL = [[NSUserDefaults standardUserDefaults] stringForKey:@"serverURL"];
        //NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://192.168.1.78:5000/completion/%@/", [specimen groupid]]];
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/completion/%@", serverURL ,[specimen groupid]]];
        //NSURL *url = [NSURL URLWithString:@"http://www.hashemian.com/tools/form-post-tester.php/beLeaf999"];
        NSMutableURLRequest *mutableRequest = [NSMutableURLRequest requestWithURL:url];
        [mutableRequest setHTTPMethod:@"PUT"];
        NSDictionary *params = @{@"completion": @"true"};
        [mutableRequest setHTTPBody:[self createHTTPBodyDataWithFields:params andFileData:nil]];
        return (NSURLRequest *)mutableRequest;
    }
    return nil;
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
