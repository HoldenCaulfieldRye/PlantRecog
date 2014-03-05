//
//  BLEFDatabase.h
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BLEFSpecimen.h"
#import "BLEFObservation.h"
#import "BLEFResult.h"

@interface BLEFDatabase : NSObject

- (NSArray*)getAllSpecimens;
- (NSArray*)getSpecimenNeedingUpdate;
- (NSFetchedResultsController*)fetchSpecimen;
- (NSArray*)getObservationsFromSpecimen:(BLEFSpecimen *)specimen;
- (NSArray*)getObservationsNeedingUploading;
- (NSArray*)getResultsFromSpecimen:(BLEFSpecimen *)specimen;

- (NSManagedObject *)fetchObjectWithID:(NSManagedObjectID *)objectID;

- (BLEFSpecimen*)newSpecimen;
- (BLEFObservation*)addNewObservationToSpecimen:(BLEFSpecimen *)specimen;
- (BLEFResult*)addNewResultToSpecimen:(BLEFSpecimen *)specimen;

- (void)saveChanges;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

extern NSString * const BLEFDatabaseUpdateNotification;

@end
