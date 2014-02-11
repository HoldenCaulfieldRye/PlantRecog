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

- (void) addObservationToUploadQueue:(NSManagedObjectID *)observationID;
- (void) processQueue;
- (void) stopProcessingQueue;

@end
