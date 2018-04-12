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
    kHJOperationType_resumeAll,
    kHJOperationType_stopAll
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

/** 是否禁用进度打印日志 */
@property (readonly, nonatomic, assign) BOOL enableProgressLog;

#pragma mark - 单例方法
+ (instancetype)sharedManager;
/**
 *  禁止打印进度日志
 */
- (void)enableProgressLog:(BOOL)enable;
/**
 *  获取下载模型
 */
- (HJDownloadModel *)downloadModelWithUrl:(NSString *)url;

#pragma mark - 单任务下载控制
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

#pragma mark - 多任务下载控制
/**
 *  批量下载操作
 */
- (void)startWithDownloadModels:(NSArray<HJDownloadModel *> *)downloadModels;
/**
 *  暂停所有下载任务
 */
- (void)suspendAll;
/**
 *  恢复下载任务（进行中、已完成、等待中除外）
 */
- (void)resumeAll;
/**
 *  停止并删除下载任务
 */
- (void)stopAll;



@end
