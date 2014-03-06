//
//  BLEFServerInterface.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BLEFSpecimen, BLEFObservation;

@interface BLEFServerInterface : NSObject <NSURLConnectionDataDelegate>

extern NSString * const BLEFUploadDidSendDataNotification;
extern NSString * const BLEFJobDidReceiveDataNotification;
extern NSString * const BLEFNetworkResultNotification;
extern NSString * const BLEFDatabaseUpdateNotification;
extern NSString * const BLEFNetworkRetryNotification;

// Database
- (void) setContext:(NSManagedObjectContext*)context;

// Upload
- (BOOL) processUploads;
- (BOOL) reStartUploadProcessing;
- (BOOL) stopUploadProcessing;

// Update
- (BOOL) processUpdates;
- (BOOL) reStartUpdateProccessing;
- (BOOL) stopUpdateProcessing;

// Server Interface
- (NSURLSessionDataTask *)createUpdateTaskForSpecimen:(BLEFSpecimen *)specimen completion:(void (^)(BOOL updated))handler;
- (NSURLSessionUploadTask *)createUploadTaskForObservation:(BLEFObservation *)observation completion:(void (^)(BOOL success))handler;

@end
