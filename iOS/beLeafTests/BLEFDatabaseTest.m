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
#import "BLEFSpecimen.h"
#import "BLEFObservation.h"
#import "BLEFResult.h"

NSManagedObjectContext *testingContext;
NSPersistentStoreCoordinator *persistentStoreCoordinator;
NSManagedObjectModel *model;

extern void __gcov_flush();

@interface BLEFDatabaseTest : XCTestCase

@end

@interface BLEFDatabase (Testing)

// Expose private methods for testing

- (NSManagedObjectContext *) getContext;

@end

@implementation BLEFDatabaseTest

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

+ (void)setUp
{
    // This is called once at the start
    [super setUp];
    
    // Get Database model
    NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"BLEFDatabase")];
    NSString* path = [bundle pathForResource:@"beLeaf" ofType:@"momd"];
    NSURL *modURL = [NSURL URLWithString:path];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modURL];
    
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
    // Create Persistent Store Coordinator as a SQL file
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"beLeafTest.sqlite"];
    
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                  initWithManagedObjectModel: model];
    
    
    [persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                             configuration:nil URL:storeURL
                                                   options:nil error:nil];
    
    // Create Context
    [self initContext];
}

- (void)initContext
{
    testingContext = [[NSManagedObjectContext alloc] init];
    [testingContext setPersistentStoreCoordinator: persistentStoreCoordinator];
    XCTAssertNotNil(testingContext, @"Database context not nil");
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    // Remove context
    testingContext = nil;
    persistentStoreCoordinator = nil;
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"beLeafTest.sqlite"];
    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
    
    [super tearDown];
}

- (BLEFDatabase *)createDatabaseWithContext:(NSManagedObjectContext *)context
{
    BLEFDatabase* database = [[BLEFDatabase alloc] init];
    [database setManagedObjectContext:context];
    return database;
}

- (void)testForNil
{
    // When there is no context to use, or nil is a parameter methods return NIL
    BLEFDatabase * database = [self createDatabaseWithContext:nil];
    XCTAssertNil([database getContext], @"Context should be NIL for this test");
    XCTAssertNil([database fetchObjectWithID:nil], @"Fetching for nil when no context correctly should return NIL");
    XCTAssertNil([database getAllSpecimens], @"Getting a groups specimens when no context should return NIL");
    XCTAssertNil([database getObservationsFromSpecimen:nil], @"Getting a specimens observations when no context correctly should return NIL");
    XCTAssertNil([database addNewObservationToSpecimen:nil], @"Adding an observation to a nil specimen should return NIL");
    XCTAssertNil([database newSpecimen], @"Adding a specimen to a group with nil correctly should return nil");
    XCTAssertNil([database addNewResultToSpecimen:nil], @"Adding a result to a nil specimen should return NIL");
}

- (void)testSpecimenInteraction
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    NSArray *specimens = [database getAllSpecimens];
    XCTAssertTrue([specimens count] == 0, @"Database should start empty");
    BLEFSpecimen *specimen = [database newSpecimen];
    specimens = [database getAllSpecimens];
    XCTAssertTrue([specimens count] == 1, @"One specimen should now exist");
    XCTAssertTrue([specimen isKindOfClass:[BLEFSpecimen class]], @"Specimen should be of type BLEFSpecimen");
}

- (void)testSpecimenNeedingUpdating
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    
    // Still uploading
    BLEFSpecimen * specimen1 = [database newSpecimen];
    [database addNewObservationToSpecimen:specimen1];
    [[database addNewObservationToSpecimen:specimen1] setUploaded:true];
    [specimen1 setGroupid:@"GROUPID111"];
    
    // Needs Updating
    BLEFSpecimen *specimen2 = [database newSpecimen];
    [[database addNewObservationToSpecimen:specimen2] setUploaded:true];
    [[database addNewObservationToSpecimen:specimen2] setUploaded:true];
    [specimen2 setGroupid:@"GROUPID222"];
    
    // Needs Updating
    BLEFSpecimen *specimen3 = [database newSpecimen];
    [[database addNewObservationToSpecimen:specimen3] setUploaded:true];
    [specimen3 setGroupid:@"GROUPID333"];
    
    // Not uploading but doesn't have a groupID
    [database newSpecimen];
    
    // Already Updated
    BLEFSpecimen *specimen4 =[database newSpecimen];
    [specimen4 setGroupid:@"GROUPID4444"];
    [database addNewResultToSpecimen:specimen4];
    [[database addNewObservationToSpecimen:specimen4] setUploaded:true];
    
    NSArray *specimenNeedingUpdating = [database getSpecimenNeedingUpdate];
    XCTAssertNotNil(specimenNeedingUpdating, @"Test: Specimen needing Updating returns an object");
    XCTAssertTrue([specimenNeedingUpdating count] == 2, @"Test: Correct number of specimen needing updating returned");
}

- (void)testFetchController
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    NSFetchedResultsController *fetchController = [database fetchSpecimen];
    XCTAssertNotNil(fetchController, @"Test: Specimen Fetch controller created");
}

- (void)testObservationInteraction
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    BLEFSpecimen *specimen = [database newSpecimen];
    NSArray *observations = [database getObservationsFromSpecimen:specimen];
    XCTAssertTrue([observations count] == 0, @"Checking no observations currently exist");
    BLEFObservation *observation = [database addNewObservationToSpecimen:specimen];
    observations = [database getObservationsFromSpecimen:specimen];
    XCTAssertTrue([observations count] == 1, @"One observation has been created");
    XCTAssertTrue([observation isKindOfClass:[BLEFObservation class]], @"Observation is type of BLEFObservation");
}

- (void)testObservationsNeedingUploading
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    BLEFSpecimen *specimen = [database newSpecimen];
    [[database addNewObservationToSpecimen:specimen] setFilename:@"image1.jpg"];
    [[database addNewObservationToSpecimen:specimen] setFilename:@"image2.jpg"];
    
    BLEFSpecimen *spcimen2 = [database newSpecimen];
    [database addNewObservationToSpecimen:spcimen2];
    [[database addNewObservationToSpecimen:spcimen2] setFilename:@"image3.jpg"];
    [[database addNewObservationToSpecimen:spcimen2] setUploaded:true];
    
    NSArray *obNeedingUploading = [database getObservationsNeedingUploading];
    XCTAssertNotNil(obNeedingUploading, @"Test: Array of observations needing uploading is returned");
    XCTAssertTrue([obNeedingUploading count] == 3, @"Test: The 3 Observations needing uploading were returned");
    
}

- (void)testFetchingObject
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    BLEFSpecimen *specimen = [database newSpecimen];
    NSManagedObjectID *objID = [specimen objectID];
    NSManagedObject *fetchedObj = [database fetchObjectWithID:objID];
    XCTAssertTrue([fetchedObj isKindOfClass:[BLEFSpecimen class]], @"Fetched object is of correct type");
}

- (void)testFetchingDeletedObject
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    BLEFSpecimen *specimen = [database newSpecimen];
    NSManagedObjectID *objID = [specimen objectID];
    NSManagedObject *fetchedObj = [database fetchObjectWithID:objID];
    
    // Reset context (removing object)
    [database setManagedObjectContext:nil];
    
    // Open new context
    [self initContext];
    
    // Re-attempt fetch
    fetchedObj = [database fetchObjectWithID:objID];
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

- (BLEFObservation *) generateTestObservationWithDataBase:(BLEFDatabase *)database
{
    BLEFSpecimen *specimen = [database newSpecimen];
    BLEFObservation *observation = [database addNewObservationToSpecimen:specimen];
    XCTAssertTrue([observation isKindOfClass:[BLEFObservation class]], @"Generating a test observation object");
    return observation;
}

- (void)testObservationThumbnail
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    UIImage *image = [self generateTestImage];
    BLEFObservation *observation = [self generateTestObservationWithDataBase:database];

    UIImage *thumbnail = [observation getThumbnail];
    XCTAssertNil(thumbnail, @"Default thumbnail is NIL");
    
    [observation generateThumbnailFromImage:image];
    thumbnail = [observation getThumbnail];
    XCTAssertNotNil(thumbnail, @"After being set thumbnail is not nil");
    XCTAssertTrue([thumbnail isKindOfClass:[UIImage class]], @"A returned thumbnail is of type UIImage");
}

- (void)testObservationSaveOpenImage
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    UIImage *image = [self generateTestImage];
    NSData *imageAsData = UIImageJPEGRepresentation(image, 1.0);
    BLEFObservation *observation = [self generateTestObservationWithDataBase:database];
    
    __block BOOL waitingForBlock = YES;
    __block BOOL result = NO;
    
    
    [observation saveImage:imageAsData  completion:^(BOOL success){
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

- (void) testCreatingResult
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    BLEFSpecimen *specimen = [database newSpecimen];
    BLEFResult *result = [database addNewResultToSpecimen:specimen];
    XCTAssertNotNil(result, @"Created result should not be nill");
}

- (void) testGettingResults
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    BLEFSpecimen *specimen = [database newSpecimen];
    NSArray *results = [database getResultsFromSpecimen:specimen];
    XCTAssertTrue([results count] == 0, @"Should be no results");
    [database addNewResultToSpecimen:specimen];
    results = [database getResultsFromSpecimen:specimen];
    XCTAssertTrue([results count] == 1, @"Should be one result returned");
    BLEFResult *fetchedResult = [results firstObject];
    XCTAssertTrue([fetchedResult isKindOfClass:[BLEFResult class]], @"Returned result should be of type BLEFResult");
}

- (void) testSave
{
    BLEFDatabase * database = [self createDatabaseWithContext:testingContext];
    [database saveChanges];
}


@end
