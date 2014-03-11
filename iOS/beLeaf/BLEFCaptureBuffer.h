//
//  BLEFCaptureBuffer.h
//  beLeaf
//
//  Created by Ashley Cutmore on 11/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BLEFDatabase.h"

@interface BLEFCaptureBuffer : NSObject <CLLocationManagerDelegate>

- (id)initWithSlots:(NSArray *)slotNames usingContext:(NSManagedObjectContext *)context;
- (BOOL)addData:(NSData *)data toSlot:(NSString *)slotName;
- (BOOL)removeDataForSlot:(NSString *)slotName;
- (UIImage*)imageForSlotNamed:(NSString *)slotName;
- (BOOL)completeSlotNamed:(NSString *)slotName completion:(void (^) (BOOL success))handler;
- (NSInteger)count;
- (BOOL)slotComplete:(NSString *)slotName;
- (void)completeCapture;
@property (strong, nonatomic) BLEFDatabase *database;

@end
