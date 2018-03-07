//
//  HJDownloadManager.h
//  HJNetworkService
//
//  Created by WHJ on 16/7/5.
//  Copyright © 2016年 WHJ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HJDownloadHeaders.h"

typedef NS_ENUM(NSUInteger, HJOperationType) {
    kHJOperationType_startAll,
    kHJOperationType_suspendAll ,
    kHJOperationType_resumeAll
};

#define kHJDownloadManager [HJDownloadManager sharedManager]

@class HJDownloadModel;

@interface HJDownloadManager : NSObject


@property (nonatomic, strong, readonly) NSMutableArray * downloadModels;

@property (nonatomic, strong, readonly) NSMutableArray * completeModels;

@property (nonatomic, strong, readonly) NSMutableArray * downloadingModels;

@property (nonatomic, strong, readonly) NSMutableArray * pauseModels;

@property (nonatomic, strong, readonly) NSMutableArray * waitModels;

@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;


+ (instancetype)sharedManager;
/**
 *  开始下载
 */
- (void)startWithDownloadModel:(HJDownloadModel *)model;
/**
 *  暂停下载
 */
- (void)suspendWithDownloadModel:(HJDownloadModel *)model;
/**
 *  恢复下载
 */
- (void)resumeWithDownloadModel:(HJDownloadModel *)model;
/**
 *  取消下载 (取消下载后 operation将从队列中移除 并 移除下载模型和对应文件)
 */
- (void)stopWithDownloadModel:(HJDownloadModel *)model;

- (void)startWithDownloadModels:(NSArray<HJDownloadModel *> *)downloadModels;

- (void)suspendAllDownloadTasks;

- (void)resumeAllDownloadTasks;

- (void)stopAllDownloadTasks;
/**
 *  获取下载模型
 */
- (HJDownloadModel *)downloadModelWithUrl:(NSString *)url;



#pragma mark - 文件操作相关
/**
 *  保存数据
 */
- (void)saveData;

/**
 *  移除目录下所有文件
 */
- (void)removeAllFiles;


#pragma mark - 后台任务相关
- (void)getBackgroundTask;

- (void)endBackgroundTask;

@end
