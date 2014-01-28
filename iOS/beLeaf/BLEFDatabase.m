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

+ (NSArray*)getImagesFromSpecimen:(BLEFSpecimen *)specimen
{
    NSArray* array = nil;
    if (specimen != nil){
        array = [specimen.images allObjects];
    }
    return array;
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
