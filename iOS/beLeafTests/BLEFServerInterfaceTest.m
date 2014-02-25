//
//  BLEFServerInterfaceTest.m
//  beLeaf
//
//  Created by Ashley Cutmore on 25/02/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h> // To force _gcov_flush (coverage files)
#import "BLEFServerInterface.h"
#import "BLEFServerConnection.h"
#import "BLEFObservation.h"
#import "BLEFDatabase.h"

NSManagedObjectContext *testingContext;
NSPersistentStoreCoordinator *persistentStoreCoordinator;
NSString *imagePath;

extern void __gcov_flush();

@interface BLEFServerInterfaceTest : XCTestCase

@end

@interface BLEFServerInterface (testing)

// Expose private methods for testing
- (id) nextInUploadQueue;
- (id) nextInJobQueue;
- (void) removeFromJobQueue:(id)objectToRemove;
- (void) removeFromUploadQueue:(id)objectToRemove;
- (void) processUploadQueue;
- (void) processJobQueue;
- (BLEFServerConnection *)createUploadConnectionFor:(NSManagedObjectID *)observationID;
- (BLEFServerConnection *)createJobConnectionFor:(NSManagedObjectID *)observationID;

@end

@implementation BLEFServerInterfaceTest

+ (void)setUp
{
    [super setUp];
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
    UIImage *testImage = [self generateTestImage];
    NSData *imagedata = UIImageJPEGRepresentation(testImage, 1.0);
    NSString *imageDirectory = [self getImageDirectory];
    NSString* pathToFile = [imageDirectory stringByAppendingPathComponent:@"test.jpg"];
    [[NSFileManager defaultManager] createFileAtPath:pathToFile contents:imagedata attributes:nil];
    imagePath = pathToFile;
}

+ (void)tearDown
{
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    NSArray *stores = [persistentStoreCoordinator persistentStores];
    [[testingContext persistentStoreCoordinator] removePersistentStore:[stores firstObject] error:nil];
    __gcov_flush(); // Flush coverage files
    [super tearDown];
}

+ (UIImage*) generateTestImage
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(150, 150), YES, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:1.0] set];
    CGContextFillPath(context);
    UIImage *blackImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return blackImage;
}

+ (NSString *)getImageDirectory
{
    NSArray *directories = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                               NSUserDomainMask, YES);
    NSString *documentsDirectory = [directories objectAtIndex:0];
    return documentsDirectory;
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    [self initContext];
}

- (void)initContext
{
    testingContext = [[NSManagedObjectContext alloc] init];
    [testingContext setPersistentStoreCoordinator: persistentStoreCoordinator];
    XCTAssertNotNil(testingContext, @"Database context not nil");
    [BLEFDatabase setContext:testingContext];
}

- (BLEFServerInterface *)createServerInterface
{
    BLEFServerInterface *serverInterface = [[BLEFServerInterface alloc] init];
    [serverInterface setContext:testingContext];
    return serverInterface;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [BLEFDatabase setContext:nil];
    testingContext = nil;
    [super tearDown];
}

- (BLEFObservation *) generateTestObservation
{
    [BLEFDatabase ensureGroupsExist];
    BLEFGroup *group = (BLEFGroup *)[[BLEFDatabase getGroups] firstObject];
    BLEFSpecimen *specimen = [BLEFDatabase addNewSpecimentToGroup:group];
    BLEFObservation *observation = [BLEFDatabase addNewObservationToSpecimen:specimen];
    XCTAssertTrue([observation isKindOfClass:[BLEFObservation class]], @"Generating a test observation object");
    [observation setFilename:@"test.jpg"];
    return observation;
}

- (void)testAddingObservationToUploadQueue
{
    BLEFServerInterface *serverInterface = [self createServerInterface];
    BLEFObservation *observation = [self generateTestObservation];
    [serverInterface addObservationToUploadQueue:[observation objectID]];
    id nextup = [serverInterface nextInUploadQueue];
    XCTAssertNotNil(nextup, @"Asserting an object has been added to the queue");
}

- (void)testAddingObservationToJobQueue
{
    BLEFServerInterface *serverInterface = [self createServerInterface];
    BLEFObservation *observation = [self generateTestObservation];
    [serverInterface addObservationToJobQueue:[observation objectID]];
    id nextup = [serverInterface nextInJobQueue];
    XCTAssertNotNil(nextup, @"Assering an object has been added to the queue");
}

- (void)testRemovingObservationFromUploadQueue
{
    BLEFServerInterface *serverInterface = [self createServerInterface];
    BLEFObservation *observation = [self generateTestObservation];
    [serverInterface addObservationToUploadQueue:[observation objectID]];
    [serverInterface removeFromUploadQueue:[observation objectID]];
    id nextup = [serverInterface nextInUploadQueue];
    XCTAssertNil(nextup, @"Assering object has been removed from queue");
}

- (void)testRemovingObservationFromJobQueue
{
    BLEFServerInterface *serverInterface = [self createServerInterface];
    BLEFObservation *observation = [self generateTestObservation];
    [serverInterface addObservationToJobQueue:[observation objectID]];
    [serverInterface removeFromJobQueue:[observation objectID]];
    id nextup = [serverInterface nextInJobQueue];
    XCTAssertNil(nextup, @"Assering object has been removed from queue");
}

- (void)testEnablingEmptyQueues
{
    BLEFServerInterface *serverInterface = [self createServerInterface];
    [serverInterface enableQueueProcessing];
}

- (void)testStoppingQueues
{
    BLEFServerInterface *serverInterface = [self createServerInterface];
    [serverInterface stopProcessingQueue];
}

- (void)testUploadQueueProcess
{
    BLEFServerInterface *serverInterface = [self createServerInterface];
    BLEFObservation *observation = [self generateTestObservation];
    [serverInterface addObservationToUploadQueue:[observation objectID]];
    [serverInterface processUploadQueue];
}

- (void)testJobQueueProcess
{
    BLEFServerInterface *serverInterface = [self createServerInterface];
    BLEFObservation *observation = [self generateTestObservation];
    [observation setJob:@"ABC123"];
    [serverInterface addObservationToJobQueue:[observation objectID]];
    [serverInterface processJobQueue];
}

@end
