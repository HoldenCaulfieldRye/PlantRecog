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
#import "BLEFServerConnection.h"

@interface BLEFServerInterface ()

@property (strong, nonatomic) NSMutableArray *uploadQueue;
@property (strong, nonatomic) NSMutableArray *jobQueue;
@property (nonatomic) BOOL uploadQueueProcessingActive;
@property (nonatomic) BOOL jobQueueProcessingActive;
@property (nonatomic) BOOL uploadQueueHalted;
@property (nonatomic) BOOL jobQueueHalted;

@end

@implementation BLEFServerInterface

- (id)init
{
    self = [super init];
    if (self){
        _uploadQueue = [[NSMutableArray alloc] init];
        _jobQueue = [[NSMutableArray alloc] init];
        _uploadQueueProcessingActive = false;
        _jobQueueProcessingActive = false;
        _uploadQueueHalted = false;
        _jobQueueHalted = false;
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(newObservationNotification:)
                       name:BLEFNewObservationNotification object:nil];
        [center addObserver:self selector:@selector(queueItemFinishedNotification:)
                       name:BLEFNetworkResultNotification object:nil];
        [center addObserver:self selector:@selector(enableQueueProcessing)
                       name:BLEFNetworkRetryNotification object:nil];
    }
    return self;
}

#pragma mark - PUBLIC

#pragma mark Database Methods

- (void) setContext:(NSManagedObjectContext*)context
{
    _managedObjectContext = context;
}

#pragma mark Queue  Methods


- (void) addObservationToUploadQueue:(NSManagedObjectID *)observationID
{
    if (observationID){
        [_uploadQueue addObject:observationID];
    }
}

- (void) addObservationToJobQueue:(NSManagedObjectID *)observationID
{
    if (observationID){
        [_jobQueue addObject:observationID];
    }
}

- (void) enableQueueProcessing
{
    _jobQueueHalted = false;
    _uploadQueueHalted = false;
    [self processJobQueue];
    [self processUploadQueue];
}

- (void) stopProcessingQueue
{
    _jobQueueHalted = true;
    _uploadQueueHalted = true;
}

#pragma mark Server Interface Methods

- (BOOL)uploadObservation:(NSManagedObjectID *)observationID
{
    if (observationID != nil){
        BLEFServerConnection *connection = [self createUploadConnectionFor:observationID];
        if (connection != nil){
            [connection start];
            return true;
        }
    }
    return false;
}

- (BOOL)updateJobForObservation:(NSManagedObjectID *)observationID
{
    if (observationID != nil){
        BLEFServerConnection *connection = [self createJobConnectionFor:observationID];
        if (connection != nil){
            [connection start];
            return true;
        }
    }
    return false;
}

#pragma mark Notifications Methods

NSString * const BLEFUploadDidSendDataNotification = @"BLEFUploadDidSendDataNotification";
NSString * const BLEFJobDidReceiveDataNotification = @"BLEFJobDidReceiveDataNotification";
NSString * const BLEFNetworkResultNotification = @"BLEFNetworkResultNotification";
NSString * const BLEFNewObservationNotification = @"BLEFNewObservationNotification";
NSString * const BLEFNetworkRetryNotification = @"BLEFNetworkRetryNotification";

- (void) newObservationNotification:(NSNotification *)notification
{
    // get observationID
    NSDictionary *notificationInfo = [notification userInfo];
    NSManagedObjectID *observationID = notificationInfo [@"objectID"];
    // add to queue
    [self addObservationToUploadQueue:observationID];
    [self processUploadQueue];
}

- (void) queueItemFinishedNotification:(NSNotification *)notification
{
    // Check for error
    [self processJobQueue];
    [self processUploadQueue];
}


#pragma mark - PRIVATE

- (id) nextInUploadQueue
{
    id nextUp = nil;
    if (_uploadQueue != nil){
        if ([_uploadQueue count] > 0){
            nextUp = [_uploadQueue firstObject];
            if ([nextUp isKindOfClass:[NSManagedObjectID class]]){
                return nextUp;
            } else {
                [self removeFromUploadQueue:nextUp];
                return nil;
            }
        }
    }
    return nextUp;
}

- (id) nextInJobQueue
{
    id nextUp = nil;
    if (_jobQueue != nil){
        if ([_jobQueue count] > 0){
            nextUp = [_jobQueue firstObject];
            if ([nextUp isKindOfClass:[NSManagedObjectID class]]){
                return nextUp;
            } else {
                [self removeFromJobQueue:nextUp];
                    return nil;
            }
        }
    }
    return nextUp;
}

- (void) removeFromJobQueue:(id)objectToRemove
{
    [_jobQueue removeObjectIdenticalTo:objectToRemove];
}

- (void) removeFromUploadQueue:(id)objectToRemove
{
    [_uploadQueue removeObjectIdenticalTo:objectToRemove];
}

- (void) processUploadQueue
{
    if (!_uploadQueueProcessingActive && !_uploadQueueHalted){
        _uploadQueueProcessingActive = true;
        id nextInQueue = [self nextInUploadQueue];
        if (nextInQueue != nil){
            [self uploadObservation:nextInQueue];
        } else {
            _uploadQueueProcessingActive = false;
            return;
        }
    }
}

- (void) processJobQueue
{
    if (!_jobQueueProcessingActive && !_jobQueueHalted){
        _jobQueueProcessingActive = true;
        id nextInQueue = [self nextInJobQueue];
        if (nextInQueue != nil){
            [self updateJobForObservation:nextInQueue];
        } else {
            _jobQueueProcessingActive = false;
            return;
        }
    }
}

- (void) updateJobForObservationAfterDelay:(NSManagedObjectID *)observationID
{
    [self performSelector:@selector(updateJobForObservation:) withObject:observationID afterDelay:1.0f];
}

- (BLEFServerConnection *)createUploadConnectionFor:(NSManagedObjectID *)observationID
{
    NSManagedObject* fetchedObject = [self fetchObjectWithID:observationID];
    if (fetchedObject != nil){
        BLEFObservation* observation = (BLEFObservation *)fetchedObject;
        if (![observation uploaded]){
            NSData *imageData = [observation getImageData];
            if (imageData == nil){
                return nil;
            }
            //NSString *urlString = @"http://sheltered-ridge-6203.herokuapp.com/upload";
            //NSString *urlString = @"http://192.168.1.78:5000/upload";
            NSString *urlString = @"http://plantrecogniser.no-ip.biz:55580/upload";
            //NSString *urlString = @"http://www.posttestserver.com/post.php";
            NSDictionary *params = @{@"segment": ([observation segment] != nil ? [observation segment] : @"na")};
            BLEFServerConnection *serverConnection = [self uploadFields:params andFileData:imageData toUrl:urlString];
            [serverConnection setObjID:observationID];
            [serverConnection setUpload:true];
            return serverConnection;
        }
    }
    // Else
    return nil;
}

- (BLEFServerConnection *)createJobConnectionFor:(NSManagedObjectID *)observationID
{
    NSManagedObject* fetchedObject = [self fetchObjectWithID:observationID];
    if (fetchedObject != nil){
        BLEFObservation *observation = (BLEFObservation *)fetchedObject;
        NSString *jobID = [observation job];
        if (jobID && ([jobID length] > 2)){
            //NSString *urlString = @"http://192.168.1.78:5000/job";
            NSString *urlString = @"http://plantrecogniser.no-ip.biz:55580/job";
            NSDictionary *params = @{@"jobID": jobID};
            //NSString *testjobID = @"52ff886a27d625b55344093e";
            //NSDictionary *params = @{@"jobID": testjobID};
            BLEFServerConnection *serverConnection = [self GETwithFields:params toUrl:urlString];
            [serverConnection setObjID:observationID];
            [serverConnection setJobUpdate:true];
            return serverConnection;
        }
    }
    // Else
    return nil;
}

#pragma mark Connection Methods

- (BLEFServerConnection *)uploadFields:(NSDictionary *)parameters andFileData:(NSData *)fileData toUrl:(NSString *)urlString
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request addValue:contentType forHTTPHeaderField:@"Content-Type"];
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
        [body appendData:[@"Content-Disposition: form-data; name=\"datafile\"; filename=\"test.jpg\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:fileData]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [request setHTTPBody:body];
    BLEFServerConnection *serverConnection = [[BLEFServerConnection alloc] initWithRequest:request delegate:self startImmediately:false];
    return serverConnection;
}

- (BLEFServerConnection *)GETwithFields:(NSDictionary *)parameters toUrl:(NSString *)urlString
{
    __block NSString *urlFields = @"";
    if (parameters){
        [parameters enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL *stop){
            urlFields = [urlFields stringByAppendingFormat:@"/%@", value];
        }];
    }
    NSURL *url = [NSURL URLWithString:[urlString stringByAppendingString:urlFields]];
    NSLog(@"GET URL = %@", url);
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"GET"];
    BLEFServerConnection *serverConnection = [[BLEFServerConnection alloc] initWithRequest:request delegate:self startImmediately:false];
    return serverConnection;
}

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
            NSManagedObject *obj = [BLEFDatabase fetchObjectWithID:[serverConnection objID]];
            if (obj){
                BLEFObservation *observation = (BLEFObservation *)obj;
                [observation setUploadProgress:[progress floatValue]];
            }
        }
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    BLEFServerConnection *serverConnection = (BLEFServerConnection *)connection;
    
    NSString *dataAsString = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
    NSLog(@"didReceiveData:%@", dataAsString);
    
    if (serverConnection.upload) {
        NSError* error;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSString *jobID = json[@"id"];
        
        if (jobID){
            BLEFObservation *observation = (BLEFObservation *)[self fetchObjectWithID:[serverConnection objID]];
            if (observation != NULL){
                if (jobID) {
                    [observation setJob:jobID];
                    [observation setUploaded:true];
                    [self saveDatabaseChanges];
                }
            }
        }
    }
    
    if (serverConnection.jobUpdate){
        NSError* error;
        NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        NSString *classification = json[@"classification"];
        bool jobComplete = false;
        if (classification){
            BLEFObservation *observation = (BLEFObservation *)[self fetchObjectWithID:[serverConnection objID]];
            if (observation != NULL){
                [observation setResult:classification];
                [self saveDatabaseChanges];
                jobComplete = true;
                NSDictionary *jobInfo = @{
                                             @"status" : [NSNumber numberWithBool:true],
                                             @"objectID"   : [serverConnection objID]
                                             };
                [[NSNotificationCenter defaultCenter] postNotificationName:BLEFJobDidReceiveDataNotification object:nil userInfo:jobInfo];
            }
        }
        if (!jobComplete){
            NSDictionary *jobInfo = @{
                                      @"status" : [NSNumber numberWithBool:false],
                                      @"objectID"   : [serverConnection objID]
                                      };
            [[NSNotificationCenter defaultCenter] postNotificationName:BLEFJobDidReceiveDataNotification object:nil userInfo:jobInfo];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    BLEFServerConnection *serverConnection = (BLEFServerConnection *)connection;
    if (serverConnection.upload){
        NSDictionary *retryInfo = @{
                                    @"job" : [NSNumber numberWithBool:false],
                                    @"upload" : [NSNumber numberWithBool:true],
                                    @"objectID"   : [serverConnection objID],
                                    @"fail" : [NSNumber numberWithBool:true]
                                    };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLEFNetworkResultNotification object:nil userInfo:retryInfo];
    }
    if (serverConnection.jobUpdate){
        NSDictionary *retryInfo = @{
                                    @"job" : [NSNumber numberWithBool:true],
                                    @"upload" : [NSNumber numberWithBool:false],
                                    @"objectID"   : [serverConnection objID],
                                    @"fail" : [NSNumber numberWithBool:true]
                                    };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLEFNetworkResultNotification object:nil userInfo:retryInfo];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    BLEFServerConnection *serverConnection = (BLEFServerConnection *)connection;
    if (serverConnection.upload){
        NSDictionary *retryInfo = @{
                                    @"job" : [NSNumber numberWithBool:false],
                                    @"upload" : [NSNumber numberWithBool:true],
                                    @"objectID"   : [serverConnection objID],
                                    @"fail" : [NSNumber numberWithBool:false]
                                    };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLEFNetworkResultNotification object:nil userInfo:retryInfo];
    }
    if (serverConnection.jobUpdate){
        NSDictionary *retryInfo = @{
                                    @"job" : [NSNumber numberWithBool:true],
                                    @"upload" : [NSNumber numberWithBool:false],
                                    @"objectID"   : [serverConnection objID],
                                    @"fail" : [NSNumber numberWithBool:false]
                                    };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLEFNetworkResultNotification object:nil userInfo:retryInfo];
    }
}

#pragma mark - Core Data Methods

- (void)saveDatabaseChanges
{
    NSError *error = nil;
    if (_managedObjectContext != nil) {
        if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (NSManagedObject *)fetchObjectWithID:(NSManagedObjectID *)objectID
{
    if (_managedObjectContext != nil){
        NSError* error = nil;
        NSManagedObject* object = [_managedObjectContext existingObjectWithID:objectID error:&error];
        return object;
    }
    return nil;
}


//TODO: Subscribe to changes in other context

@end
