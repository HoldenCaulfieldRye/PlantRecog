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
#import "BLEFObservation.h"
#import "BLEFDatabase.h"

NSManagedObjectContext *testingContext;
NSPersistentStoreCoordinator *persistentStoreCoordinator;
NSString *imagePath;

extern void __gcov_flush();

@interface BLEFServerInterfaceTest : XCTestCase

@end

@interface BLEFServerInterface (testing)

// Expose Database For Testing
@property (strong, nonatomic) BLEFDatabase * database;

// Expose private methods for testing
- (BLEFObservation *) nextInUploadQueue;
- (BOOL) updateObservation:(NSManagedObjectID *)observationID usingData:(NSData *)data andError:(NSError *)error;
- (BOOL) updateSpecimen:(NSManagedObjectID *)specimenID usingData:(NSData *)data andError:(NSError *)error;

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
}

+ (void)tearDown
{
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    NSArray *stores = [persistentStoreCoordinator persistentStores];
    [[testingContext persistentStoreCoordinator] removePersistentStore:[stores firstObject] error:nil];
    __gcov_flush(); // Flush coverage files
    [super tearDown];
}

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

- (NSString *)getImageDirectory
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
    UIImage *testImage = [self generateTestImage];
    NSData *imagedata = UIImageJPEGRepresentation(testImage, 1.0);
    NSString *imageDirectory = [self getImageDirectory];
    NSString* pathToFile = [imageDirectory stringByAppendingPathComponent:@"test.jpg"];
    [[NSFileManager defaultManager] createFileAtPath:pathToFile contents:imagedata attributes:nil];
    imagePath = @"test.jpg";

}

- (void)initContext
{
    testingContext = [[NSManagedObjectContext alloc] init];
    [testingContext setPersistentStoreCoordinator: persistentStoreCoordinator];
    XCTAssertNotNil(testingContext, @"Database context not nil");
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
    testingContext = nil;
    [super tearDown];
}

- (BLEFObservation *)createTestObservation:(BLEFServerInterface *)server
{
    BLEFDatabase *serverDB = [server database];
    BLEFSpecimen *specimen = [serverDB newSpecimen];
    BLEFObservation *observation = [serverDB addNewObservationToSpecimen:specimen];
    return observation;
}

- (BLEFSpecimen *)createTestSpecimen:(BLEFServerInterface *)server
{
    BLEFDatabase *serverDB = [server database];
    return [serverDB newSpecimen];
}

- (void)testInit
{
    BLEFServerInterface *server = [self createServerInterface];
    XCTAssertNotNil(server, @"Test:Server is initialised");
}

- (void)testUploadQueueEmpty
{
    BLEFServerInterface *server = [self createServerInterface];
    BLEFObservation *nextInQueue = [server nextInUploadQueue];
    XCTAssertNil(nextInQueue, @"Test: Queue is empty");
}

-(void)testUploadQueueInsertion
{
    BLEFServerInterface *server = [self createServerInterface];
    [self createTestObservation:server];
    BLEFObservation *nextInQueue = [server nextInUploadQueue];
    XCTAssertNotNil(nextInQueue, @"Test: Queue Inserted ID");
}

-(void)testCreateUploadTask
{
    BLEFServerInterface *server = [self createServerInterface];
    BLEFObservation *observation = [self createTestObservation:server];
    [observation setSegment:@"Branch"];
    [observation setFilename:imagePath];
    NSURLSessionUploadTask *task = [server createUploadTaskForObservation:observation completion:nil];
    XCTAssertNotNil(task, @"Test: Upload Task generated");
}

-(void)testCreateUpdateTask
{
    BLEFServerInterface *server = [self createServerInterface];
    BLEFSpecimen *specimen = [self createTestSpecimen:server];
    [specimen setGroupid:@"ABCDEFGHIKJLMNOP"];
    NSURLSessionDataTask *task = [server createUpdateTaskForSpecimen:specimen completion:nil];
    XCTAssertNotNil(task, @"Test: Update Task generated");
}

-(void)testObservationUpdate
{
    BLEFServerInterface *server = [self createServerInterface];
    BLEFObservation *observation = [self createTestObservation:server];
    XCTAssertFalse([observation uploaded], @"Test: Observation starts as not-uploaded");
    
    NSString *jsonResponse = @"{\"groupID\":\"123ABC\"}";
    
    NSData *dataFromServer = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding];
    
    bool returned = [server updateObservation:[observation objectID] usingData:dataFromServer andError:nil];
    
    XCTAssertTrue(returned, @"Test: Method returned true");
    XCTAssertTrue([observation uploaded], @"Test: Observation marked as uploaded after receiving data from server");
    XCTAssertEqualObjects([[observation specimen] groupid], @"123ABC", @"Test: Obsevation's GroupID correctly set from server response data");
}

-(void)testSpecimenUpdate
{
    BLEFServerInterface *server = [self createServerInterface];
    BLEFSpecimen *specimen = [self createTestSpecimen:server];
    
    NSString *jsonResponse = @"{\"classification\":\"oak\"}";
    NSData *dataFromServer = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding];
    
    bool returned = [server updateSpecimen:[specimen objectID] usingData:dataFromServer andError:nil];
    
    XCTAssertTrue(returned, @"Test: Method returned true");
    
}


@end
