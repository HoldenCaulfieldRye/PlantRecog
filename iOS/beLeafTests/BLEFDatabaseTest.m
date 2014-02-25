//
//  BLEFDatabaseTest.m
//  beLeaf
//
//  Created by Ashley Cutmore on 22/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h> // To force _gcov_flush (coverage files)
#import "BLEFDatabase.h"
#import "BLEFGroup.h"
#import "BLEFSpecimen.h"
#import "BLEFObservation.h"

NSManagedObjectContext *testingContext;
NSPersistentStoreCoordinator *persistentStoreCoordinator;
extern void __gcov_flush();

@interface BLEFDatabaseTest : XCTestCase


@end

@interface BLEFDatabase (Testing)

+ (NSManagedObjectContext *) getContext;

@end

@implementation BLEFDatabaseTest

+ (void)setUp
{
    // This is called once at the start
    [super setUp];
    
    // Get Database model
    NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"BLEFDatabase")];
    NSString* path = [bundle pathForResource:@"beLeaf" ofType:@"momd"];
    NSURL *modURL = [NSURL URLWithString:path];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modURL];
    
    // Create Persistent Store Coordinator in memory
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                           initWithManagedObjectModel: model];
    [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                configuration:nil URL:nil
                                                options:nil error:nil];
}

+ (void)tearDown
{
    // This is called once at the end
    NSArray *stores = [persistentStoreCoordinator persistentStores];
    [[testingContext persistentStoreCoordinator] removePersistentStore:[stores firstObject] error:nil];
    __gcov_flush(); // Flush coverage files
    [super tearDown];
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    // Create Context
    [self initContext];
}

- (void)initContext
{
    testingContext = [[NSManagedObjectContext alloc] init];
    [testingContext setPersistentStoreCoordinator: persistentStoreCoordinator];
    XCTAssertNotNil(testingContext, @"Database context not nil");
    [BLEFDatabase setContext:testingContext];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    // Remove context
    testingContext = nil;
    [super tearDown];
}

- (void)testForNil
{
    // When there is no context to use, or nil is a parameter methods return NIL
    [BLEFDatabase setContext:nil];
    XCTAssertNil([BLEFDatabase getContext], @"Context is set to NIL for tests");
    XCTAssertNil([BLEFDatabase getGroups], @"Getting groups when no context correctly returns NIL");
    XCTAssertNil([BLEFDatabase fetchObjectWithID:nil], @"Fetching for nil when no context correctly returns NIL");
    XCTAssertNil([BLEFDatabase getSpecimensFromGroup:nil], @"Getting a groups specimens when no context correctly return NIL");
    XCTAssertNil([BLEFDatabase getObservationsFromSpecimen:nil], @"Getting a specimens observations when no context correctly returns NIL");
    XCTAssertNil([BLEFDatabase addNewObservationToSpecimen:nil], @"Adding an observation to a speimen when nil corrctly returns NIL");
    XCTAssertNil([BLEFDatabase addNewSpecimentToGroup:nil], @"Adding a specimen to a group with nil correctly returns nil");
}

- (void)testGettingGroups
{
    // Add a group
    [BLEFDatabase ensureGroupsExist];
    
    // Try and fetch the group
    NSArray *groups = [BLEFDatabase getGroups];
    XCTAssertNotNil(groups, @"Getting the DB's specimen groups");
    id firstobject = [groups firstObject];
    XCTAssertNotNil(firstobject, @"Getting the first specimen group");
    XCTAssertTrue([firstobject isKindOfClass:[BLEFGroup class]], @"The first specimen group can be cast as a group");
}

- (void)testSpecimenInteraction
{
    [BLEFDatabase ensureGroupsExist];
    NSArray *groups = [BLEFDatabase getGroups];
    BLEFGroup *group = (BLEFGroup*)[groups firstObject];
    NSArray *specimens = [BLEFDatabase getSpecimensFromGroup:group];
    XCTAssertTrue([specimens count] == 0, @"Checking no specimen currently exist");
    BLEFSpecimen *specimen = [BLEFDatabase addNewSpecimentToGroup:group];
    specimens = [BLEFDatabase getSpecimensFromGroup:group];
    XCTAssertTrue([specimens count] == 1, @"Checking one specimen currently exist");
    XCTAssertTrue([specimen isKindOfClass:[BLEFSpecimen class]], @"Specimen is of type BLEFSpecimen");
}

- (void)testObservationInteraction
{
    [BLEFDatabase ensureGroupsExist];
    BLEFGroup *group = (BLEFGroup *)[[BLEFDatabase getGroups] firstObject];
    BLEFSpecimen *specimen = [BLEFDatabase addNewSpecimentToGroup:group];
    NSArray *observations = [BLEFDatabase getObservationsFromSpecimen:specimen];
    XCTAssertTrue([observations count] == 0, @"Checking no observations currently exist");
    BLEFObservation *observation = [BLEFDatabase addNewObservationToSpecimen:specimen];
    observations = [BLEFDatabase getObservationsFromSpecimen:specimen];
    XCTAssertTrue([observations count] == 1, @"One observation has been created");
    XCTAssertTrue([observation isKindOfClass:[BLEFObservation class]], @"Observation is type of BLEFObservation");
}

- (void)testFetchingObject
{
    [BLEFDatabase ensureGroupsExist];
    BLEFGroup *group = (BLEFGroup *)[[BLEFDatabase getGroups] firstObject];
    BLEFSpecimen *specimen = [BLEFDatabase addNewSpecimentToGroup:group];
    NSManagedObjectID *objID = [specimen objectID];
    NSManagedObject *fetchedObj = [BLEFDatabase fetchObjectWithID:objID];
    XCTAssertTrue([fetchedObj isKindOfClass:[BLEFSpecimen class]], @"Fetched object is of correct type");
}

- (void)testFetchingDeletedObject
{
    [BLEFDatabase ensureGroupsExist];
    BLEFGroup *group = (BLEFGroup *)[[BLEFDatabase getGroups] firstObject];
    BLEFSpecimen *specimen = [BLEFDatabase addNewSpecimentToGroup:group];
    NSManagedObjectID *objID = [specimen objectID];
    NSManagedObject *fetchedObj = [BLEFDatabase fetchObjectWithID:objID];
    
    // Reset context (removing object)
    [BLEFDatabase setContext:nil];
    
    // Open new context
    [self initContext];
    
    // Re-attempt fetch
    fetchedObj = [BLEFDatabase fetchObjectWithID:objID];
    XCTAssertNil(fetchedObj, @"Fetching deleted object returns nil");
}

#pragma mark Observations

- (UIImage*) generateTestImage
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(150, 150), YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0] set];
    CGContextFillPath(context);
    UIImage *blackImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return blackImage;
}

- (BLEFObservation *) generateTestObservation
{
    [BLEFDatabase ensureGroupsExist];
    BLEFGroup *group = (BLEFGroup *)[[BLEFDatabase getGroups] firstObject];
    BLEFSpecimen *specimen = [BLEFDatabase addNewSpecimentToGroup:group];
    BLEFObservation *observation = [BLEFDatabase addNewObservationToSpecimen:specimen];
    XCTAssertTrue([observation isKindOfClass:[BLEFObservation class]], @"Generating a test observation object");
    return observation;
}

- (void)testObservationThumbnail
{
    UIImage *image = [self generateTestImage];
    BLEFObservation *observation = [self generateTestObservation];

    UIImage *thumbnail = [observation getThumbnail];
    XCTAssertNil(thumbnail, @"Default thumbnail is NIL");
    
    [observation generateThumbnailFromImage:image];
    thumbnail = [observation getThumbnail];
    XCTAssertNotNil(thumbnail, @"After being set thumbnail is not nil");
    XCTAssertTrue([thumbnail isKindOfClass:[UIImage class]], @"A returned thumbnail is of type UIImage");
}

- (void)testObservationSaveOpenImage
{
    UIImage *image = [self generateTestImage];
    BLEFObservation *observation = [self generateTestObservation];
    
    __block BOOL waitingForBlock = YES;
    __block BOOL result = NO;
    
    
    [observation saveImage:image completion:^(BOOL success){
        waitingForBlock = NO;
        result = success;
    }];
    
    while(waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    XCTAssertTrue(result, @"File save return value true on success");
    UIImage *savedImage = [observation getImage];
    XCTAssertNotNil(savedImage, @"Saved Image retrival");
    
    NSData *imageData = [observation getImageData];
    XCTAssertNotNil(imageData, @"Saved ImageData retrival");
    
    [testingContext deleteObject:observation];
    [observation willSave];
    imageData = [observation getImageData];
    XCTAssertNil(imageData, @"ImageData should be deleted");
}


@end
