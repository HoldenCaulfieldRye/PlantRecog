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
#import "../Pods/OHHTTPStubs/OHHTTPStubs/Sources/OHHTTPStubs.h"

NSManagedObjectContext *testingContext;
NSPersistentStoreCoordinator *persistentStoreCoordinator;
NSString *imagePath;
NSManagedObjectModel *model;

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
- (void) uploadErrorWaitAndRetry;

@end

@implementation BLEFServerInterfaceTest

+ (void)setUp
{
    [super setUp];
    NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"BLEFDatabase")];
    NSString* path = [bundle pathForResource:@"beLeaf" ofType:@"momd"];
    NSURL *modURL = [NSURL URLWithString:path];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modURL];
    
    [OHHTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return YES;
    } withStubResponse:^OHHTTPStubsResponse *(NSURLRequest *request) {
        NSString *jsonResponse = @"{\"group_id\": \"group123\" , \"classification\": \"Oak Tree\" }";
        NSData *dataFromServer = [jsonResponse dataUsingEncoding:NSUTF8StringEncoding];
        return [OHHTTPStubsResponse responseWithData:dataFromServer statusCode:200 headers:nil];
    }];
}

+ (void)tearDown
{
    [[NSFileManager defaultManager] removeItemAtPath:imagePath error:nil];
    NSArray *stores = [persistentStoreCoordinator persistentStores];
    [[testingContext persistentStoreCoordinator] removePersistentStore:[stores firstObject] error:nil];
    __gcov_flush(); // Flush coverage files
    [super tearDown];
    [OHHTTPStubs removeAllStubs];
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
    
    // Create Persistent Store Coordinator in memory
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                  initWithManagedObjectModel: model];
    [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                             configuration:nil URL:nil
                                                   options:nil error:nil];
    
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
    [[serverInterface database] setDisableSaves:true];
    return serverInterface;
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    persistentStoreCoordinator = nil;
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
    [[self createTestObservation:server] setFilename:@"image1.jpg"];
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

-(void)testSendUpdateTask
{
    BLEFServerInterface *server = [self createServerInterface];
    BLEFSpecimen *specimen = [self createTestSpecimen:server];
    [specimen setGroupid:@"ABCDEFGHIKJLMNOP"];
    
    __block BOOL waitingForBlock = YES;
    __block BOOL result = NO;
    
    
    NSURLSessionDataTask *task = [server createUpdateTaskForSpecimen:specimen completion:^(BOOL updated){
        waitingForBlock = NO;
        result = updated;
    }];
    XCTAssertNotNil(task, @"Test: Update Task generated");
    [task resume];
    
    while(waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    XCTAssertTrue(result, @"Test: Sending Resonse To Updated specimen");
}

-(void)testObservationUpdate
{
    BLEFServerInterface *server = [self createServerInterface];
    BLEFObservation *observation = [self createTestObservation:server];
    XCTAssertFalse([observation uploaded], @"Test: Observation starts as not-uploaded");
    
    NSString *jsonResponse = @"{\"group_id\":\"123ABC\"}";
    
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

- (void)testProcessZeroUpdates
{
    BLEFServerInterface *server = [self createServerInterface];
    BOOL update = [server processUpdates];
    XCTAssertFalse(update, @"Test processing updates returns false when nothing to update");
}

- (void)testProcessZeroUploads
{
    BLEFServerInterface *server = [self createServerInterface];
    BOOL uploads = [server processUploads];
    XCTAssertFalse(uploads, @"Test processing updates returns false if nothing to upload");
}

- (void)testStartAndStopQueues
{
    BLEFServerInterface *server = [self createServerInterface];
    [server stopUpdateProcessing];
    [server stopUploadProcessing];
    [server reStartUpdateProccessing];
    [server reStartUploadProcessing];
}

- (void)testProcessUploads
{
    BLEFServerInterface *server = [self createServerInterface];
    BLEFObservation *observation = [self createTestObservation:server];
    [observation setSegment:@"Branch"];
    [observation setFilename:imagePath];
    BOOL uploads = [server processUploads];
    XCTAssertTrue(uploads, @"Test processing an upload returns true");
}

- (void)testProcessingUploadOfEmptyObservation
{
    BLEFServerInterface *server = [self createServerInterface];
    [self createTestObservation:server];
    BOOL uploads = [server processUploads];
    XCTAssertFalse(uploads, @"Test processing an upload with no attributes returns false");
}

- (void)testUpdatingSpecimen
{
    BLEFServerInterface *server = [self createServerInterface];
    BLEFObservation *observation = [self createTestObservation:server];
    [observation setUploaded:true];
    [[observation specimen] setGroupid:@"ABC123"];
    [server processUpdates];
}

- (void)test_processUpdates
{
    BLEFServerInterface *server = [self createServerInterface];
    BLEFObservation *observation = [self createTestObservation:server];
    [observation setUploaded:true];
    [[observation specimen] setGroupid:@"ABC123"];
    
    BLEFObservation *observation2 = [self createTestObservation:server];
    [observation2 setUploaded:true];
    [[observation2 specimen] setGroupid:@"ABC321"];
    [server reStartUpdateProccessing];
    [server processUpdates];
}

- (void) test_networkRetry
{
    BLEFServerInterface *server = [self createServerInterface];
    [server uploadErrorWaitAndRetry];
}

@end
