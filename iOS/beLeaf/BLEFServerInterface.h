//
//  BLEFServerInterface.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEFServerInterface : NSObject <NSURLConnectionDataDelegate>

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
extern NSString * const BLEFUploadDidSendDataNotification;
extern NSString * const BLEFJobDidReceiveDataNotification;
extern NSString * const BLEFNetworkResultNotification;
extern NSString * const BLEFNewObservationNotification;
extern NSString * const BLEFNetworkRetryNotification;

// Database
- (void) setContext:(NSManagedObjectContext*)context;

// Queue
- (void) addObservationToUploadQueue:(NSManagedObjectID *)observationID;
- (void) addObservationToJobQueue:(NSManagedObjectID *)observationID;
- (void) enableQueueProcessing;
- (void) stopProcessingQueue;


// Server Interface
- (BOOL)uploadObservation:(NSManagedObjectID *)observationID;
- (BOOL)updateJobForObservation:(NSManagedObjectID *)observationID;

// Notifications
- (void) newObservationNotification:(NSNotification *)notification;
- (void) queueItemFinishedNotification:(NSNotification *)notification;

@end
