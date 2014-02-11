//
//  BLEFDatabase.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFDatabase.h"
#import "BLEFAppDelegate.h"

@implementation BLEFDatabase

+ (BLEFAppDelegate *)getAppDelegate
{
    return [[UIApplication sharedApplication] delegate];
}

+ (NSManagedObjectContext *)getContext
{
    BLEFAppDelegate *appDelegate = [self getAppDelegate];
    return [appDelegate managedObjectContext];
}

+ (void)saveChanges
{
    BLEFAppDelegate *appDelegate = [self getAppDelegate];
    [appDelegate saveContext];
}

+ (NSArray*)getGroups
{
    NSManagedObjectContext *context = [self getContext];
    // Construct request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Group" inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // Sort ascending
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDesriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDesriptors];
    
    // Fetch
    NSError *error = nil;
    NSArray* array = [context executeFetchRequest:fetchRequest error:&error];

    return array;
}

+ (NSArray*)getSpecimensFromGroup:(BLEFGroup *)group;
{
    NSArray* array = nil;
    if (group != nil){
        array = [group.specimens allObjects];
    }
    return array;
}

+ (NSArray*)getObservationsFromSpecimen:(BLEFSpecimen *)specimen
{
    NSArray* array = nil;
    if (specimen != nil){
        array = [specimen.observations allObjects];
    }
    return array;
}

+ (NSManagedObject *)fetchObjectWithID:(NSManagedObjectID *)objectID
{
    NSManagedObjectContext *context = [self getContext];
    NSError* error = nil;
    NSManagedObject* object = [context existingObjectWithID:objectID error:&error];
    return object;
}

+ (BLEFSpecimen*)addNewSpecimentToGroup:(BLEFGroup *)group
{
    NSManagedObjectContext *context = [self getContext];
    BLEFSpecimen *specimen = [NSEntityDescription insertNewObjectForEntityForName:@"Specimen" inManagedObjectContext:context];
    
    NSDate* now = [NSDate date];
    specimen.created = [now timeIntervalSince1970];
    
    [group addSpecimensObject:specimen];
    [specimen setGroup:group];
    
    return specimen;
}

+ (BLEFObservation*)addNewObservationToSpecimen:(BLEFSpecimen *)specimen
{
    NSManagedObjectContext *context = [self getContext];
    BLEFObservation *observation = [NSEntityDescription insertNewObjectForEntityForName:@"Observation" inManagedObjectContext:context];
    
    NSDate* now = [NSDate date];
    observation.date = [now timeIntervalSince1970];
    
    [observation setSpecimen:specimen];
    [specimen addObservationsObject:observation];
    
    return observation;
}

+ (void) ensureGroupsExist
{
    NSArray* groups = [self getGroups];
    if (groups == nil || [groups count] == 0) {
        [self createStartingPoint];
    }
}

+ (void)createStartingPoint
{
    NSLog(@"createStartPoint");
    NSManagedObjectContext *context = [self getContext];
    [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:context];
    [self saveChanges];
}

@end
