//
//  pebble_tutorial1Tests.m
//  pebble-tutorial1Tests
//
//  Created by Ross, Jason on 1/11/16.
//  Copyright (c) 2016 Ross, Jason. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface pebble_tutorial1Tests : XCTestCase

@end

@implementation pebble_tutorial1Tests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
