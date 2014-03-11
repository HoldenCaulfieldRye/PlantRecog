//
//  BLEFSpecimen.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class BLEFObservation, BLEFResult;

@interface BLEFSpecimen : NSManagedObject

@property (nonatomic) BOOL complete;
@property (nonatomic) NSTimeInterval created;
@property (nonatomic, retain) NSString * groupid;
@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) BOOL updatePolling;
@property (nonatomic, retain) NSSet * observations;
@property (nonatomic, retain) NSSet * results;
@end

@interface BLEFSpecimen (CoreDataGeneratedAccessors)

- (void)addObservationsObject:(BLEFObservation *)value;
- (void)removeObservationsObject:(BLEFObservation *)value;
- (void)addObservations:(NSSet *)values;
- (void)removeObservations:(NSSet *)values;

- (void)addResultsObject:(BLEFResult *)value;
- (void)removeResultssObject:(BLEFResult *)value;
- (void)addResults:(NSSet *)values;
- (void)removeResults:(NSSet *)values;


@end
