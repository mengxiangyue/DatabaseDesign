//
//  JZDatabaseClient.h
//  DatabaseDesign
//
//  Created by wenba201600164 on 16/4/8.
//  Copyright © 2016年 wenba201600164. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kDatabaseVersion @"kDatabaseVersion"

typedef void (^executedFinishHandler) (BOOL isSuccess);
typedef void (^queryResultHandler) (BOOL isSuccess, NSArray *results);

@interface JZDatabaseClient : NSObject

+ (instancetype)sharedInstance;

/**
 *  升级
 *
 *  @param isForce 是否强制
 *  @param handler 非强制更新的时候该参数有用
 *
 *  @return 强制的话不会立即返回
 */
- (BOOL)updateDatabaseIsForce:(BOOL)isForce finishHandler:(executedFinishHandler)handler;

#pragma mark - 组装sql语句
- (NSString *)createInsertSqlWithTable:(NSString *)tableName dataDictionary:(NSDictionary *)dataDictionary;

- (NSString *)createUpdateSqlWithTable:(NSString *)tableName dataDictionary:(NSDictionary *)dataDictionary condition:(NSString *)contion;

- (NSString *)createDeleteSqlWithTable:(NSString *)tableName condition:(NSString *)condition;

- (NSString *)createQuerySqlWithTable:(NSString *)tableName condition:(NSString *)condition;


#pragma mark - 执行sql语句
// 同步sync开头
// 异步以async开头 异步会立即返回YES 真正的是否成功需要在回调block里面判断
- (BOOL)syncExecuteSql:(NSString *)sql;
- (BOOL)asyncExecuteSql:(NSString *)sql finishHandler:(executedFinishHandler)handler;

- (BOOL)syncExecuteBatchSql:(NSArray *)sqls;
- (BOOL)asyncExecuteBatchSql:(NSArray *)sqls finishHandler:(executedFinishHandler)handler;;

- (NSArray *)syncExecuteQuerySql:(NSString *)sql;
- (NSArray *)asyncExecuteQuerySql:(NSString *)sql resultHandler:(queryResultHandler)handler;;

- (void)mapTableColumnsIsAsync:(BOOL)isAsync;
@end
