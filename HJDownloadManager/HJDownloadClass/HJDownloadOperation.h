//
//  HJDownloadOperation.h
//  HJNetworkService
//
//  Created by WHJ on 16/7/5.
//  Copyright © 2016年 WHJ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DownloadStatusChangedBlock)(void);

@class HJDownloadModel;

@interface HJDownloadOperation : NSOperation


@property (nonatomic, weak) HJDownloadModel * downloadModel;

@property (nonatomic, strong) NSURLSessionDataTask * downloadTask;

@property (nonatomic ,weak) NSURLSession *session;

/** 下载状态改变回调 */
@property (nonatomic, copy) DownloadStatusChangedBlock downloadStatusChangedBlock ;

- (instancetype)initWithDownloadModel:(HJDownloadModel *)downloadModel andSession:(NSURLSession *)session;


- (void)suspend;
- (void)resume;


@end
