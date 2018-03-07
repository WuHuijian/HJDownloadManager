//
//  HJDownloadManager.h
//  HJNetworkService
//
//  Created by WHJ on 16/7/5.
//  Copyright © 2016年 WHJ. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, HJOperationType) {
    kHJOperationType_start,
    kHJOperationType_suspend ,
    kHJOperationType_resume,
    kHJOperationType_stop
};

#define kHJDownloadManager [HJDownloadManager sharedManager]

@class HJDownloadModel;

@interface HJDownloadManager : NSObject


@property (nonatomic, strong, readonly) NSMutableArray * downloadModels;

@property (nonatomic, strong, readonly) NSMutableArray * completeModels;

@property (nonatomic, strong, readonly) NSMutableArray * downloadingModels;

@property (nonatomic, strong, readonly) NSMutableArray * pauseModels;

@property (nonatomic, strong, readonly) NSMutableArray * waitModels;



@property (nonatomic, strong, readonly) NSURLSession * currentSession;

@property (nonatomic, assign) NSInteger maxConcurrentOperationCount;

@property (nonatomic, assign) BOOL backgroundDownload;//是否后台下载

+ (instancetype)sharedManager;
/**
 *  添加下载对象
 */
- (void)addDownloadModel:(HJDownloadModel *)model;

- (void)addDownloadModels:(NSArray<HJDownloadModel *> *)models;

/**
 *  开始下载
 *
 *  @param model 下载模型
 */

- (void)startWithDownloadModel:(HJDownloadModel *)model;

/**
 *  重新添加下载任务 （暂停||失败）状态下调用
 *
 *  @param model 下载模型
 */
- (void)restartWithDownloadModel:(HJDownloadModel *)model;
/**
 *  暂停下载
 */
- (void)suspendWithDownloadModel:(HJDownloadModel *)model;
/**
 *  恢复下载
 */
- (void)resumeWithDownloadModel:(HJDownloadModel *)model;

/**
 *  取消下载
 */
- (void)stopWithDownloadModel:(HJDownloadModel *)model;


- (void)startAllDownloadTasks;

- (void)suspendAllDownloadTasks;

- (void)resumeAllDownloadTasks;

- (void)stopAllDownloadTasks;

/**
 *  保存数据
 */

- (void)saveData;

/**
 *  获取下载模型
 */
- (HJDownloadModel *)downloadModelWithUrl:(NSString *)url;

/**
 *  移除下载模型
 */
- (void)removeDownloadModelWithModel:(HJDownloadModel *)downloadModel;

/**
 *  移除全部下载模型（包括下载文件）
 */
- (void)removeAll;


- (void)getBackgroundTask;

- (void)endBackgroundTask;

@end
