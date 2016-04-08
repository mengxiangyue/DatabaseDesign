//
//  JZDatabaseClientTests.m
//  DatabaseDesign
//
//  Created by wenba201600164 on 16/4/8.
//  Copyright © 2016年 wenba201600164. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "JZDatabaseClient.h"

@interface JZDatabaseClientTests : XCTestCase

@property (strong, nonatomic) JZDatabaseClient *client;

@end

@implementation JZDatabaseClientTests

- (void)setUp {
    [super setUp];
    self.client = [JZDatabaseClient sharedInstance];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSetup {
    NSDictionary *data = @{
                            @"test": @"11",
                            @"test2": @"222"
                            };
    NSString *sql = [self.client createInsertSqlWithTable:@"test" dataDictionary:data];
    NSAssert([sql isEqualToString:@"insert into test (test2,test) values  ('222','11')"], @"失败");
}
@end
