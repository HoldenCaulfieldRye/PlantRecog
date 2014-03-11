//
//  BLEFCaptureBufferTest.m
//  beLeaf
//
//  Created by Ashley Cutmore on 11/03/2014.
//  Copyright (c) 2014 DocMcs13group12. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h> // To force _gcov_flush (coverage files)
#import "BLEFCaptureBuffer.h"
#import "BLEFDatabase.h"

NSManagedObjectContext *testingContext;
NSPersistentStoreCoordinator *persistentStoreCoordinator;
NSManagedObjectModel *model;

extern void __gcov_flush();

@interface BLEFCaptureBufferTest : XCTestCase

@end

@implementation BLEFCaptureBufferTest

+(void)setUp
{
    [super setUp];
    NSBundle *bundle = [NSBundle bundleForClass:NSClassFromString(@"BLEFDatabase")];
    NSString* path = [bundle pathForResource:@"beLeaf" ofType:@"momd"];
    NSURL *modURL = [NSURL URLWithString:path];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modURL];
    NSLog(@"+setUp()");
}

+(void)tearDown
{
    NSArray *stores = [persistentStoreCoordinator persistentStores];
    [[testingContext persistentStoreCoordinator] removePersistentStore:[stores firstObject] error:nil];
    __gcov_flush();
    NSLog(@"+TearDown()");
    [super tearDown];
}

- (void)setUp
{
    [super setUp];
    NSLog(@"-Setup()");
    // Put setup code here; it will be run once, before the first test case.
    
    [self initContext];
}

- (void)initContext
{
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]
                                  initWithManagedObjectModel: model];
    [persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                             configuration:nil URL:nil
                                                   options:nil error:nil];

    testingContext = [[NSManagedObjectContext alloc] init];
    [testingContext setPersistentStoreCoordinator: persistentStoreCoordinator];
    XCTAssertNotNil(testingContext, @"Database context not nil");
}

- (void)tearDown
{
    // Put teardown code here; it will be run once, after the last test case.
    persistentStoreCoordinator = nil;
    testingContext = nil;
    NSLog(@"-tearDown()");
    [super tearDown];
}

- (void)testInit
{
    BLEFDatabase *database = [[BLEFDatabase alloc] init];
    [database setManagedObjectContext:testingContext];
    BLEFCaptureBuffer *testBuffer = [[BLEFCaptureBuffer alloc] initWithSlots:@[@"entire", @"leaf"] usingDatabase:database];
    XCTAssertNotNil(testBuffer, @"Test init'ing buffer returns a reference");
    XCTAssertTrue([testBuffer count] == 2, @"Test: Buffer has two slots as per init");
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

- (void)testAddandRetrieveData
{
    BLEFDatabase *database = [[BLEFDatabase alloc] init];
    [database setManagedObjectContext:testingContext];
    BLEFCaptureBuffer *testBuffer = [[BLEFCaptureBuffer alloc] initWithSlots:@[@"entire"] usingDatabase:database];
    UIImage *testImage = [self generateTestImage];
    NSData *imageData = UIImageJPEGRepresentation(testImage, 1.0f);
    
    XCTAssertTrue([testBuffer addData:imageData toSlot:@"entire"], @"Test: inserting data returns true");
    XCTAssertFalse([testBuffer addData:imageData toSlot:@"foobar"], @"Test: inserting data to wrong slot returns false");
    
    testImage = nil;
    testImage = [testBuffer imageForSlotNamed:@"entire"];
    XCTAssertNotNil(testImage, @"Test: image for slot successfully returned");
}

- (void)testAddAndDeleteData
{
    BLEFDatabase *database = [[BLEFDatabase alloc] init];
    [database setManagedObjectContext:testingContext];
    BLEFCaptureBuffer *testBuffer = [[BLEFCaptureBuffer alloc] initWithSlots:@[@"entire"] usingDatabase:database];
    UIImage *testImage = [self generateTestImage];
    NSData *imageData = UIImageJPEGRepresentation(testImage, 1.0f);
    XCTAssertTrue([testBuffer addData:imageData toSlot:@"entire"], @"Test: Adding data returned true");
    XCTAssertTrue([testBuffer removeDataForSlot:@"entire"], @"Test: Removing data returend true");
    XCTAssertNil([testBuffer imageForSlotNamed:@"entire"], @"Test: Slot data deleated");
}

- (void)testSlotSave
{
    BLEFDatabase *database = [[BLEFDatabase alloc] init];
    [database setManagedObjectContext:testingContext];
    BLEFCaptureBuffer *testBuffer = [[BLEFCaptureBuffer alloc] initWithSlots:@[@"entire"] usingDatabase:database];
    UIImage *testImage = [self generateTestImage];
    NSData *imageData = UIImageJPEGRepresentation(testImage, 1.0f);
    XCTAssertTrue([testBuffer addData:imageData toSlot:@"entire"], @"Test: Adding data returned true");
    
    __block BOOL waitingForBlock = true;
    
    XCTAssertTrue([testBuffer completeSlotNamed:@"entire" completion:^(BOOL success) {
        waitingForBlock = false;
    }], @"Test: Completing slot returned true");
    
    while(waitingForBlock) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    }
    
    XCTAssertTrue([testBuffer slotComplete:@"entire"], @"Test: Slot marked as complete");
}

- (void)testCompleteCapture
{
    BLEFDatabase *database = [[BLEFDatabase alloc] init];
    [database setManagedObjectContext:testingContext];
    BLEFCaptureBuffer *testBuffer = [[BLEFCaptureBuffer alloc] initWithSlots:@[@"entire"] usingDatabase:database];
    [testBuffer completeCapture];
}

- (void)testDeleteSession
{
    BLEFDatabase *database = [[BLEFDatabase alloc] init];
    [database setManagedObjectContext:testingContext];
    BLEFCaptureBuffer *testBuffer = [[BLEFCaptureBuffer alloc] initWithSlots:@[@"entire"] usingDatabase:database];
    [testBuffer deleteSession];
}


@end
