//
//  JZDatabaseClient.m
//  DatabaseDesign
//
//  Created by wenba201600164 on 16/4/8.
//  Copyright © 2016年 wenba201600164. All rights reserved.
//

#import "JZDatabaseClient.h"
#import <fmdb.h>

// check字符串
#define CHECK_STRING_VALID(targetString)				\
(targetString != nil && [targetString isKindOfClass:[NSString class]] && [targetString length] > 0)

#define CHECK_STRING_INVALID(targetString)              \
(targetString == nil || ![targetString isKindOfClass:[NSString class]] || [targetString length] == 0)

// check数组
#define CHECK_ARRAY_INVALID(targetArray)              \
(targetArray == nil || ![targetArray isKindOfClass:[NSArray class]] || [targetArray count] == 0)

#define CHECK_ARRAY_VALID(targetArray)              \
(targetArray != nil && [targetArray isKindOfClass:[NSArray class]] &&  [targetArray count] > 0)

// check字典
#define CHECK_DICTIONARY_VALID(targetDictionary)              \
(targetDictionary != nil && [targetDictionary isKindOfClass:[NSDictionary class]])

#define CHECK_DICTIONARY_INVALID(targetDictionary)              \
(targetDictionary == nil || ![targetDictionary isKindOfClass:[NSDictionary class]])

@interface NSString (Concat)
- (NSString *)concat:(NSString *)string;
@end

@implementation NSString (Concat)
- (NSString *)concat:(NSString *)string {
    return [NSString stringWithFormat:@"%@%@", self, string];
}

@end

#define kDatabaseName @"jz.sqlite"

@interface JZDatabaseClient ()
@property (strong, nonatomic) FMDatabaseQueue *databaseQueue;
@property (strong, nonatomic) NSDictionary *tableColumnsDictions;
@end


@implementation JZDatabaseClient

+ (instancetype)sharedInstance {
    static JZDatabaseClient *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[JZDatabaseClient alloc] init];
        [instance mapTableColumnsIsAsync:NO];
    });
    return instance;
}

- (BOOL)updateDatabaseIsForce:(BOOL)isForce finishHandler:(executedFinishHandler)handler {
    NSArray *needExecuteSqls = [self getWillExecuteSqls];
    if (isForce) {
        BOOL isSuccess = [self syncExecuteBatchSql:needExecuteSqls];
        if (isSuccess) {
            [self updateDatabaseVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
        }
        return isSuccess;
    } else {
        return [self asyncExecuteBatchSql:needExecuteSqls finishHandler:^(BOOL isSuccess) {
            if (isSuccess) {
                [self updateDatabaseVersion:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]];
            }
            handler(isSuccess);
        }];
    }
}

- (NSArray *)getWillExecuteSqls {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *oldVersion = [defaults objectForKey:kDatabaseVersion] ? [defaults objectForKey:kDatabaseVersion] : @"0";
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    NSDictionary *upateSqlDict = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"db_config" ofType:@"plist"]] objectForKey:@"upgrade"];
    NSArray *allKeys = [upateSqlDict allKeys];
    allKeys = [allKeys sortedArrayWithOptions:NSSortConcurrent usingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 compare:obj2 options:NSNumericSearch] == NSOrderedDescending;
    }];
    
    int startIndex = (int)[allKeys indexOfObject:oldVersion];
    if (startIndex == -1) {
        startIndex = 0;
    }
    int endIndex = (int)[allKeys indexOfObject:currentVersion];
    if (endIndex == -1) {
        endIndex = (int)[allKeys count] - 1;
    }
    
    NSMutableArray *sqls = [[NSMutableArray alloc] init];
    for (int i = startIndex; i <= endIndex; i++) {
        NSArray *versionSqls = [upateSqlDict valueForKey:[allKeys objectAtIndex:i]];
        for (NSString *sql in versionSqls) {
            [sqls addObject:sql];
        }
    }
    return sqls;
}


#pragma mark - 组装sql语句
- (NSString *)createInsertSqlWithTable:(NSString *)tableName dataDictionary:(NSDictionary *)dataDictionary {
    NSString *sql = @"";
    if (CHECK_STRING_INVALID(tableName) || CHECK_DICTIONARY_INVALID(dataDictionary)) {
        return sql;
    }
    sql = [[sql concat:@"insert into "] concat:tableName];
    
    NSArray *keys = [dataDictionary allKeys];
    NSMutableSet *set = [[NSMutableSet alloc] initWithArray:keys];
    if ([self.tableColumnsDictions valueForKey:tableName]) {
        [set intersectSet:[self.tableColumnsDictions valueForKey:tableName]];
    }
    keys = set.allObjects;
    
    
    NSString *columns = @" (";
    NSString *values = @" (";
    for (int i = 0; i < [keys count]; i++) {
        NSString *key = [keys objectAtIndex:i];
        columns = [columns concat:key];
        values = [[[values concat:@"'"] concat:[dataDictionary valueForKey:key]] concat:@"'"];
        if (i != [keys count] - 1) {
            columns = [columns concat:@","];
            values = [values concat:@","];
        }
    }
    columns = [columns concat:@")"];
    values = [values concat:@")"];
    
    sql = [[[sql concat:columns] concat:@" values "] concat:values];
    return sql;
}

- (BOOL)syncExecuteSql:(NSString *)sql {
    __block BOOL result = NO;
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    return result;
}

- (BOOL)asyncExecuteSql:(NSString *)sql finishHandler:(executedFinishHandler)handler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        BOOL result = NO;
        result = [self syncExecuteSql:sql];
        dispatch_async(dispatch_get_main_queue(), ^{
            handler(result);
        });
    });
    return YES;
}

- (BOOL)syncExecuteBatchSql:(NSArray *)sqls {
    __block BOOL result = NO;
    [self.databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        for (NSString *sql in sqls) {
            result = [db executeUpdate:sql];
            if (!result) {
                *rollback = YES;
                return;
            }
        }
    }];
    return result;
}

#pragma mark - utils
- (NSString *)getDocumentPath {
    NSArray * pathArray = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentsDirectory = [pathArray objectAtIndex:0];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:documentsDirectory])
    {
        [fileManager createDirectoryAtPath:documentsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return  documentsDirectory;
}

/**
 *  更新UserDefault中的数据库版本
 *
 *  @param version
 */
- (void)updateDatabaseVersion:(NSString *)version {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:version forKey:kDatabaseVersion];
    [defaults synchronize];
    [self mapTableColumnsIsAsync:YES];
}

/**
 *  生成数据库中的字段对应表
 */
- (void)mapTableColumnsIsAsync:(BOOL)isAsync {
    if (!self.tableColumnsDictions) {
        self.tableColumnsDictions = [[NSMutableDictionary alloc] init];
    }
    if (isAsync) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self mapTableColumns];
        });
    } else {
        [self mapTableColumns];
    }
}

- (void)mapTableColumns {
    NSDictionary *tables = [[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"db_config" ofType:@"plist"]] objectForKey:@"tables"];
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        for (NSString *tableName in tables) {
            NSMutableSet *columnArray = [[NSMutableSet alloc] init];
            FMResultSet *rs = [db getTableSchema:tableName];
            while ([rs next]) {
                [columnArray addObject:[rs stringForColumn:@"name"]];
            }
            [self.tableColumnsDictions setValue:columnArray forKey:tableName];
        }
    }];
}


#pragma mark - getter/setter
- (FMDatabaseQueue *)databaseQueue {
    if (!_databaseQueue) {;
        NSString *path = [NSString stringWithFormat:@"%@/%@", [self getDocumentPath], kDatabaseName];
        NSLog(path);
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:path];
    }
    return _databaseQueue;
}

@end
