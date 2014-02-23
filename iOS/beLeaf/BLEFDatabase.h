//
//  BLEFDatabase.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEFGroup.h"
#import "BLEFSpecimen.h"
#import "BLEFObservation.h"

@interface BLEFDatabase : NSObject

+ (NSArray*)getGroups;
+ (NSArray*)getSpecimensFromGroup:(BLEFGroup *)group;
+ (NSArray*)getObservationsFromSpecimen:(BLEFSpecimen *)specimen;

+ (BLEFSpecimen*)addNewSpecimentToGroup:(BLEFGroup *)group;
+ (BLEFObservation*)addNewObservationToSpecimen:(BLEFSpecimen *)specimen;

+ (NSManagedObject *)fetchObjectWithID:(NSManagedObjectID *)objectID;

+ (void)saveChanges;

+ (void) ensureGroupsExist;
+ (void) createStartingPoint;
+ (void) setContext:(NSManagedObjectContext*)context;

@end
