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


extern void __gcov_flush();

@interface BLEFServerInterfaceTest : XCTestCase

@end

@implementation BLEFServerInterfaceTest

+ (void)tearDown
{
    __gcov_flush(); // Flush coverage files
    [super tearDown];
}

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testNetworkQueue
{
    
}

@end
