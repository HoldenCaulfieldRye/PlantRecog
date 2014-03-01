//
//  BLEFServerInterface.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BLEFServerInterface : NSObject <NSURLConnectionDataDelegate>

extern NSString * const BLEFUploadDidSendDataNotification;
extern NSString * const BLEFJobDidReceiveDataNotification;
extern NSString * const BLEFNetworkResultNotification;
extern NSString * const BLEFNewObservationNotification;
extern NSString * const BLEFNetworkRetryNotification;

// Database
- (void) setContext:(NSManagedObjectContext*)context;

// Queue
- (BOOL) addObservationToUploadQueue:(NSManagedObjectID *)observationID;
- (BOOL) enableQueueProcessing;
- (BOOL) stopProcessingQueue;

// Poller
- (BOOL) addSpecimenToUpdatePool:(NSManagedObjectID *)specimenID;
- (void) startPollers;
- (void) stopPollers;

// Server Interface
- (NSURLSessionUploadTask *)createUploadTaskForObservation:(NSManagedObjectID *)observationID completion:(void (^)(BOOL success))handler;
- (NSURLSessionDataTask *)createUpdateTaskForSpecimen:(NSManagedObjectID *)specimenID completion:(void (^)(BOOL updated))handler;

@end
