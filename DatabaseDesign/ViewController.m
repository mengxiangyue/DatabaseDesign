//
//  ViewController.m
//  DatabaseDesign
//
//  Created by wenba201600164 on 16/4/8.
//  Copyright © 2016年 wenba201600164. All rights reserved.
//

#import "ViewController.h"
#import "JZDatabaseClient.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *sql = [[JZDatabaseClient sharedInstance] createInsertSqlWithTable:@"easy" dataDictionary:@{@"a": @"test", @"b": @"dfff"}];
    BOOL success = [[JZDatabaseClient sharedInstance] syncExecuteSql:@"select aaaa from easy"];
//    success = [[JZDatabaseClient sharedInstance] asyncExecuteSql:@"create table easy2 (a text)" finishHandler:^(BOOL isSuccess) {
//        NSLog(@"执行返回了");
//    }];
//
//    
//    NSArray *sqls = @[
//                        @"create table bulktest1 (id integer primary key autoincrement, x text);",
//                        @"create table bulktest2 (id integer primary key autoincrement, y text);",
//                        @"create table bulktest3 (id integer primary key autoincrement, z text);",
//                        @"insert into bulktest1 (x) values ('XXX');",
//                        @"insert into bulktest2 (y) values ('YYY');",
//                        @"insert into bulktest3 (z) values ('ZZZ');"
//                      ];
//    success = [[JZDatabaseClient sharedInstance] syncExecuteBatchSql:sqls];
//    NSLog(@"test %d", success);
    
//    BOOL success = [[[JZDatabaseClient alloc] init] updateDatabaseIsForce:YES finishHandler:^(BOOL isSuccess) {
//        
//    }];
    NSLog(@"test %d", success);
    
    [[JZDatabaseClient sharedInstance] mapTableColumnsIsAsync:YES];
    

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
