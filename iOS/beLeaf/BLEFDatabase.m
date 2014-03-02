//
//  BLEFDatabase.m
//  beLeaf
//
//  Created by Ashley Cutmore on 28/01/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import "BLEFDatabase.h"

@implementation BLEFDatabase

- (id)init
{
    self = [super init];
    if (self){
        [[NSNotificationCenter defaultCenter]   addObserver:self
                                                   selector:@selector(_mocDidSaveNotification:)
                                                       name:NSManagedObjectContextDidSaveNotification
                                                     object:nil];
    }
    return self;
}

- (NSManagedObjectContext *) getContext
{
    return [self managedObjectContext];
}

- (void)_mocDidSaveNotification:(NSNotification *)notification
{
    NSManagedObjectContext *savedContext = [notification object];
    if ([self managedObjectContext] == savedContext)
    {
        return;
    } else {
        if ([self managedObjectContext])
            [[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
    }
}

- (void)saveChanges
{
    NSError *error = nil;
    if ([self managedObjectContext] != nil) {
        if ([[self managedObjectContext] hasChanges]){
        if ([[self managedObjectContext] hasChanges] && ![[self managedObjectContext] save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        }
    }
}

- (NSArray*)getAllSpecimens
{
    NSManagedObjectContext *context = [self getContext];
    if (context == nil){
        return nil;
    }
    // Construct Request
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Specimen"
                                              inManagedObjectContext:context];
    [fetchRequest setEntity:entity];
    
    // Sort by date
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"created" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Fetch
    NSError *error = nil;
    NSArray *array = [context executeFetchRequest:fetchRequest error:&error];
    if (!error){
        return array;
    }
    return nil;
}

- (NSFetchedResultsController*)fetchSpecimen
{
    NSManagedObjectContext *context = [self getContext];
    if (context == nil){
        return nil;
    }
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Specimen"];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"created" ascending:NO]];
    
    return [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                               managedObjectContext:context
                                                 sectionNameKeyPath:nil
                                                          cacheName:nil];
}

- (NSArray*)getObservationsFromSpecimen:(BLEFSpecimen *)specimen
{
    NSArray* array = nil;
    if (specimen != nil){
        array = [specimen.observations allObjects];
    }
    return array;
}

- (NSArray*)getResultsFromSpecimen:(BLEFSpecimen *)specimen
{
    NSArray* array = nil;
    if (specimen != nil){
        array = [specimen.results allObjects];
    }
    return array;
}

- (NSManagedObject *)fetchObjectWithID:(NSManagedObjectID *)objectID
{
    NSManagedObjectContext *context = [self getContext];
    if (context == nil)
        return nil;
    NSError* error = nil;
    NSManagedObject* object = [context existingObjectWithID:objectID error:&error];
    return object;
}

- (BLEFSpecimen*)newSpecimen;
{
    NSManagedObjectContext *context = [self getContext];
    if (context == nil){
        return nil;
    }
    BLEFSpecimen *specimen = [NSEntityDescription insertNewObjectForEntityForName:@"Specimen" inManagedObjectContext:context];
    
    NSDate* now = [NSDate date];
    specimen.created = [now timeIntervalSince1970];
    return specimen;
}

- (BLEFObservation*)addNewObservationToSpecimen:(BLEFSpecimen *)specimen
{
    NSManagedObjectContext *context = [self getContext];
    if (context == nil){
        return nil;
    }
    BLEFObservation *observation = [NSEntityDescription insertNewObjectForEntityForName:@"Observation" inManagedObjectContext:context];
    
    if (observation != nil){
        [observation setSpecimen:specimen];
        [specimen addObservationsObject:observation];
        return  observation;
    }
    return nil;
}

- (BLEFResult*)addNewResultToSpecimen:(BLEFSpecimen *)specimen
{
    NSManagedObjectContext *context = [self getContext];
    if (context == nil){
        return nil;
    }
    BLEFResult *result = [NSEntityDescription insertNewObjectForEntityForName:@"Result" inManagedObjectContext:context];
    if (result != nil){
        [result setSpecimen:specimen];
        [specimen addResultsObject:result];
        return result;
    }
    return nil;
}



@end
