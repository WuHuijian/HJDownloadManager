//
//  HJDownloadOperation.m
//  HJNetworkService
//
//  Created by WHJ on 16/7/5.
//  Copyright © 2016年 WHJ. All rights reserved.
//

#import <objc/runtime.h>
#import "HJDownloadHeaders.h"

#define kKVOBlock(KEYPATH,BLOCK)\
[self willChangeValueForKey:KEYPATH];\
BLOCK();\
[self didChangeValueForKey:KEYPATH];


@interface HJDownloadOperation (){
    
    BOOL _executing;
    BOOL _finished;
    
}

@end


static const NSTimeInterval kTimeoutInterval = 60;

static NSString * const kIsExecuting = @"isExecuting";

static NSString * const kIsCancelled = @"isCancelled";

static NSString * const kIsFinished = @"isFinished";

@implementation HJDownloadOperation

MJCodingImplementation

- (instancetype)initWithDownloadModel:(HJDownloadModel *)downloadModel andSession:(NSURLSession *)session{
    self = [super init];
    if (self) {
        self.downloadModel = downloadModel;
        self.session = session;
        self.downloadModel.status = kHJDownloadStatusWaiting;
    }
    return self;
}


- (void)dealloc{
    NSLog(@"任务已销毁");
}


#pragma mark - Public Method
- (void)startRequest{
    
    //已下载完成 || 任务未就绪 --> 则直接返回
    if (self.downloadModel.isFinished || !self.isReady) {
        return;
    }
    // 创建请求
    NSURL *url = [NSURL URLWithString:self.downloadModel.urlString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kTimeoutInterval];
    
    // 设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", self.downloadModel.fileDownloadSize];
    [request setValue:range forHTTPHeaderField:@"Range"];
    
    if(!self.downloadTask){
        self.downloadTask = [self.session dataTaskWithRequest:request];
    }

    self.downloadTask.downloadModel = self.downloadModel;
    [self addObserver];
    
    [self.downloadTask resume];
}

// 进行检索获取Key
- (BOOL)observerKeyPath:(NSString *)key observer:(id )observer
{
    id info = self.downloadTask.observationInfo;
    NSArray *array = [info valueForKey:@"_observances"];
    for (id objc in array) {
        id Properties = [objc valueForKeyPath:@"_property"];
        id newObserver = [objc valueForKeyPath:@"_observer"];
        
        NSString *keyPath = [Properties valueForKeyPath:@"_keyPath"];
        if ([key isEqualToString:keyPath] && [newObserver isEqual:observer]) {
            return YES;
        }
    }
    return NO;
}

- (void)addObserver{
    
    if (![self observerKeyPath:@"state" observer:self]) {
        [self.downloadTask addObserver:self
                            forKeyPath:@"state"
                               options:NSKeyValueObservingOptionNew
                               context:nil];
    }
}

- (void)removeObserver{
    
    if ([self observerKeyPath:@"state" observer:self]){
        [self.downloadTask removeObserver:self forKeyPath:@"state"];
    }
}

- (void)suspend{
    
    kKVOBlock(kIsExecuting, ^{
        [self.downloadTask suspend];
        _executing = NO;
    });
    
}

- (void)resume{
    
    kKVOBlock(kIsExecuting, ^{
        [self startRequest];
        _executing = YES;
    });
}


- (void)completeOperation{
    
    [self willChangeValueForKey:kIsFinished];
    [self willChangeValueForKey:kIsExecuting];
    
    _executing = NO;
    _finished = YES;
    
    [self didChangeValueForKey:kIsExecuting];
    [self didChangeValueForKey:kIsFinished];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    
    if ([keyPath isEqualToString:@"state"]) {
        
        
        NSInteger newState = [[change objectForKey:@"new"] integerValue];
        NSInteger oldState = [[change objectForKey:@"old"] integerValue];
    
        switch (newState) {
            case NSURLSessionTaskStateSuspended:
                self.downloadModel.status = kHJDownloadStatus_suspended;
                //为进行任务管理 暂停任务后 直接取消
                [self cancel];
                break;
            case NSURLSessionTaskStateCompleted:{
                if (self.downloadModel.isFinished) {
                    self.downloadModel.status = kHJDownloadStatusCompleted;
                    // 关闭流
                    [self cancel];
                }else{
                    if (self.downloadModel.status == kHJDownloadStatus_suspended) {
                    }else{// 下载失败
                        self.downloadModel.status = kHJDownloadStatusFailed;
                    }
                }
            }break;
            case NSURLSessionTaskStateRunning:
                self.downloadModel.status = kHJDownloadStatus_Running;
                break;
            case NSURLSessionTaskStateCanceling:
             
                break;
            default:
                break;
        }
        
        if (newState != oldState) {
            if (self.downloadStatusChangedBlock) {
                self.downloadStatusChangedBlock();
            }
        }
    }
}

#pragma mark - Override Method
- (void)start{
    
    //重写start方法时，要做好isCannelled的判断
    if (self.cancelled) {
        [self completeOperation];
        return;
    }
    
    [self resume];

}

- (BOOL)isExecuting{
    return _executing;
}


- (BOOL)isFinished{
    return _finished;
}

- (BOOL)isConcurrent{
    return YES;
}

/**
 *  cancel方法调用后 该operation将会取消并从queue中移除，若队列中有等待中的任务，将会自动执行
 */
- (void)cancel{
    kKVOBlock(kIsCancelled, ^{
        [super cancel];
        [self.downloadTask cancel];
        [self removeObserver];
        [self.downloadModel.stream close];
        self.downloadModel.stream = nil;
        self.downloadTask = nil;
    });
    
    //start方法没做任务取消监控 所以任务取消后手动调用
    [self start];
}


#pragma mark - Private Method

@end

