//
//  BLEFServerInterface.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFServerInterface.h"
#import "BLEFDatabase.h"
#import "BLEFAppDelegate.h"
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
        [center addObserver:self selector:@selector(enableQueueProcessing) name:BLEFNetworkRetryNotification object:nil];
    }
    return self;
}

- (void) grabTasksFromSpecimen:(NSManagedObjectID *)specimenID
{
    // Fetch all observations in specimen that need uploading
}

- (void) addObservationToUploadQueue:(NSManagedObjectID *)observationID
{
    if (observationID){
        NSLog(@"image added to Upload Queue");
        [_uploadQueue addObject:observationID];
        [self processQueue];
    }
}

- (void) processQueue
{
    if (!_uploadQueueProcessingActive && !_uploadQueueHalted){
        [self processNextInUploadQueue];
    }
    if (!_jobQueueProcessingActive && !_jobQueueHalted){
        [self processNextInJobQueue];
    }
}

- (void) stopProcessingQueue
{
    _uploadQueueProcessingActive = false;
    _jobQueueProcessingActive = false;
    _jobQueueHalted = true;
    _uploadQueueHalted = true;
}

- (void) enableQueueProcessing
{
    NSLog(@"Enabling queue processing");
    _jobQueueHalted = false;
    _uploadQueueHalted = false;
    [self processQueue];
}


NSString * const BLEFUploadDidSendDataNotification = @"BLEFUploadDidSendDataNotification";
NSString * const BLEFJobDidSendDataNotification = @"BLEFJobDidSendDataNotification";
NSString * const BLEFNetworkRetryNotification = @"BLEFNetworkRetryNotification";

#pragma mark Private Methods

- (void) addObservationToJobQueue:(NSManagedObjectID *)observationID
{
    if (observationID){
        NSLog(@"image added to Job Queue");
        [_jobQueue addObject:observationID];
        [self processQueue];
    }
}

- (void)processNextInUploadQueue
{
    if ([_uploadQueue count] > 0){
        _uploadQueueProcessingActive = true;
        NSManagedObjectID *id = [_uploadQueue firstObject];
        [_uploadQueue removeObject:id];
        [self uploadObservation:id];
    } else {
        _uploadQueueProcessingActive = false;
    }
}

- (void)processNextInJobQueue
{
    if ([_jobQueue count] > 0){
        _jobQueueProcessingActive = true;
        NSManagedObjectID *id = [_jobQueue firstObject];
        [_jobQueue removeObject:id];
        [self updateJobAfterDelay:id];
    } else {
        _jobQueueProcessingActive = false;
    }
}

- (void)uploadObservation:(NSManagedObjectID *)observationID
{
    NSLog(@"Observation Upload called");
    NSManagedObject* fetchedObject = [self fetchObjectWithID:observationID];
    if (fetchedObject != nil){
        BLEFObservation* observation = (BLEFObservation *)fetchedObject;
        if (![observation uploaded]){
            NSData *imageData = [observation getImageData];
            //NSString *urlString = @"http://sheltered-ridge-6203.herokuapp.com/upload";
            //NSString *urlString = @"http://192.168.1.78:5000/upload";
            NSString *urlString = @"http://plantrecogniser.no-ip.biz:55580/upload";
            //NSString *urlString = @"http://www.posttestserver.com/post.php";
            NSDictionary *params = @{@"segment": [observation segment]};
            BLEFServerConnection *serverConnection = [self uploadFields:params andFileData:imageData toUrl:urlString];
            [serverConnection setObjID:observationID];
            [serverConnection setUpload:true];
            [serverConnection start];
        } else {
            NSLog(@"Already uploaded");
            [self processNextInUploadQueue];
        }
    } else {
        NSLog(@"Error fetching observation for upload");
        [self processNextInUploadQueue];
    }
}

- (void)updateJobAfterDelay:(NSManagedObjectID*)observationID
{
    [self performSelector:@selector(updateJobForObservation:) withObject:observationID afterDelay:1.0f];
}

- (void)updateJobForObservation:(NSManagedObjectID *)observationID
{
    NSLog(@"Job GET called");
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
            BLEFServerConnection *serverConnection = [self sendGETwithFields:params toUrl:urlString];
            [serverConnection setObjID:observationID];
            [serverConnection setJobUpdate:true];
            [serverConnection start];
        } else {
            NSLog(@"No jobID to GET");
            [self processNextInJobQueue];
        }
    } else {
        NSLog(@"Error fetching observation for job GET");
        [self processNextInJobQueue];
    }
}

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

- (BLEFServerConnection *)sendGETwithFields:(NSDictionary *)parameters toUrl:(NSString *)urlString
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
                                             @"status" : @true,
                                             @"objectID"   : [serverConnection objID]
                                             };
                [[NSNotificationCenter defaultCenter] postNotificationName:BLEFJobDidSendDataNotification object:nil userInfo:jobInfo];
                [self processNextInJobQueue];
            }
        }
        if (!jobComplete){
            [self updateJobAfterDelay:[serverConnection objID]];
        }
    }
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"Connection Failed");
    BLEFServerConnection *serverConnection = (BLEFServerConnection *)connection;
    if (serverConnection.upload){
        _uploadQueueProcessingActive = false;
        NSDictionary *uploadInfo = @{
                                     @"percentage" : @0.0,
                                     @"objectID"   : [serverConnection objID]
                                     };
        [[NSNotificationCenter defaultCenter] postNotificationName:BLEFUploadDidSendDataNotification object:nil userInfo:uploadInfo];
        [self stopProcessingQueue];
        [self addObservationToUploadQueue:[serverConnection objID]];
    }
    if (serverConnection.jobUpdate){
        [self stopProcessingQueue];
        [self addObservationToJobQueue:[serverConnection objID]];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"didFinishLoading...");
    BLEFServerConnection *serverConnection = (BLEFServerConnection *)connection;
    if (serverConnection.upload){
        NSLog(@"an Upload");
        [self addObservationToJobQueue:[serverConnection objID]];
        [self processNextInUploadQueue];
    }
    if (serverConnection.jobUpdate){
        NSLog(@"a Job");
        [self processNextInJobQueue];
    }
}

#pragma mark - Core Data Methods

- (NSManagedObjectContext *)getContext
{
    if (_managedObjectContext != nil) {
            return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [(BLEFAppDelegate *)[[UIApplication sharedApplication] delegate] persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

- (void)saveDatabaseChanges
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [self getContext];
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (NSManagedObject *)fetchObjectWithID:(NSManagedObjectID *)objectID
{
    NSManagedObjectContext *context = [self getContext];
    NSError* error = nil;
    NSManagedObject* object = [context existingObjectWithID:objectID error:&error];
    return object;
}



//TODO: Subscribe to changes in other context

@end
