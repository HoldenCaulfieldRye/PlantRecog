//
//  BLEFDatabase.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFDatabase.h"
#import "BLEFAppDelegate.h"

static NSManagedObjectContext *managedObjectContext;


@implementation BLEFDatabase

+ (void)initialize
{
    [[NSNotificationCenter defaultCenter]   addObserver:self
                                            selector:@selector(_mocDidSaveNotification:)
                                            name:NSManagedObjectContextDidSaveNotification
                                            object:nil];
}

+ (void) setContext:(NSManagedObjectContext*)context;
{
    managedObjectContext = context;
}

+ (NSManagedObjectContext *) getContext
{
    return managedObjectContext;
}

+ (void)_mocDidSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *savedContext = [notification object];
    if (managedObjectContext == savedContext)
    {
        return;
    } else {
        if (managedObjectContext)
            [managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    }
}

+ (void)saveChanges
{
    NSError *error = nil;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

+ (NSArray*)getGroups
{
    NSManagedObjectContext *context = [self getContext];
    if (context == nil)
        return nil;
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
    if (context == nil)
        return nil;
    NSError* error = nil;
    NSManagedObject* object = [context existingObjectWithID:objectID error:&error];
    return object;
}

+ (BLEFSpecimen*)addNewSpecimentToGroup:(BLEFGroup *)group
{
    NSManagedObjectContext *context = [self getContext];
    if (context == nil)
        return nil;
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
    if (context == nil)
        return nil;
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
    NSManagedObjectContext *context = [self getContext];
    if (context){
        [NSEntityDescription insertNewObjectForEntityForName:@"Group" inManagedObjectContext:context];
        [self saveChanges];
    }
}

@end
