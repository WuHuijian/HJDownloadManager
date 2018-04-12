//
//  HJDownloadManager.m
//  HJNetworkService
//
//  Created by WHJ on 16/7/5.
//  Copyright © 2016年 WHJ. All rights reserved.
//

#import "HJDownloadManager.h"
#import "HJUncaughtExceptionHandler.h"
#import "AppDelegate.h"

@interface HJDownloadManager ()<NSURLSessionDataDelegate>{
    NSMutableArray *_downloadModels;
    NSMutableArray *_completeModels;
    NSMutableArray *_downloadingModels;
    NSMutableArray *_pauseModels;
    BOOL            _enableProgressLog;
}


@property (nonatomic, strong) NSOperationQueue *queue;

@property (nonatomic, strong) NSURLSession *backgroundSession;

@end

static UIBackgroundTaskIdentifier bgTask;


@implementation HJDownloadManager


#pragma mark - 单例相关
static id instace = nil;
+ (id)allocWithZone:(struct _NSZone *)zone
{
    if (instace == nil) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instace = [super allocWithZone:zone];
            // 添加未捕获异常的监听
            [instace handleUncaughtExreption];
            // 添加监听
            [instace addObservers];
            // 创建缓存目录
            [instace createCacheDirectory];
        });
    }
    return instace;
}

- (instancetype)init
{
    return instace;
}

+ (instancetype)sharedManager
{
    return [[self alloc] init];
}

- (id)copyWithZone:(struct _NSZone *)zone
{
    return instace;
}

- (id)mutableCopyWithZone:(struct _NSZone *)zone{
    return instace;
}


#pragma mark - 单例初始化调用
/**
 *  添加监听
 */
- (void)addObservers{
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(recoverDownloadModels) name:UIApplicationDidFinishLaunchingNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(endBackgroundTask) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(getBackgroundTask) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(getBackgroundTask) name:kNotificationUncaughtException object:nil];
}

/**
 *  创建缓存目录
 */
- (void)createCacheDirectory{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:HJCachesDirectory]) {
        [fileManager createDirectoryAtPath:HJCachesDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    NSLog(@"创建缓存目录:%@",HJCachesDirectory);
}

/**
 *  添加未捕获异常的监听
 */
- (void)handleUncaughtExreption{
    
    [HJUncaughtExceptionHandler setDefaultHandler];
}

/**
 *  禁止打印进度日志
 */
- (void)enableProgressLog:(BOOL)enable{
    
    _enableProgressLog = enable;
}

#pragma mark - 模型相关
- (void)addDownloadModel:(HJDownloadModel *)model{
    if (![self checkExistWithDownloadModel:model]) {
        [self.downloadModels addObject:model];
        NSLog(@"下载模型添加成功");
    }
}

- (void)addDownloadModels:(NSArray<HJDownloadModel *> *)models{
    if ([models isKindOfClass:[NSArray class]]) {
        [models enumerateObjectsUsingBlock:^(HJDownloadModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addDownloadModel:obj];
        }];
    }
}

-(BOOL)checkExistWithDownloadModel:(HJDownloadModel *)model{
    
    for (HJDownloadModel *tmpModel in self.downloadModels) {
        if ([tmpModel.urlString isEqualToString:model.urlString]) {
            NSLog(@"Tip:下载数据模型已存在");
            return YES;
        }
    }
    return NO;
}


- (HJDownloadModel *)downloadModelWithUrl:(NSString *)url{
    for (HJDownloadModel *tmpModel in self.downloadModels) {
        if ([url isEqualToString:tmpModel.urlString]) {
            return tmpModel;
        }
    }
    return nil;
}
#pragma mark - 单任务下载控制
- (void)startWithDownloadModel:(HJDownloadModel *)model{

    if (model.status == kHJDownloadStatus_Completed) {
        return;
    }

    [self addDownloadModel:model];
    
    model.operation = [[HJDownloadOperation alloc] initWithDownloadModel:model andSession:self.backgroundSession];
    [self.queue addOperation:model.operation];
}

//暂停后操作将销毁 若想继续执行 则需重新创建operation并添加
- (void)suspendWithDownloadModel:(HJDownloadModel *)model{
    
    [self suspendWithDownloadModel:model forAll:NO];
}


- (void)suspendWithDownloadModel:(HJDownloadModel *)model forAll:(BOOL)forAll{
    if (forAll) {//暂停全部
        if (model.status == kHJDownloadStatus_Running) {//下载中 则暂停
            [model.operation suspend];
        }else if (model.status == kHJDownloadStatus_Waiting){//等待中 则取消
            [model.operation cancel];
        }
    }else{
        if (model.status == kHJDownloadStatus_Running) {
            [model.operation suspend];
        }
    }
    
    model.operation = nil;
}


- (void)resumeWithDownloadModel:(HJDownloadModel *)model{
    
    if (model.status == kHJDownloadStatus_Completed ||
        model.status == kHJDownloadStatus_Running) {
        return;
    }
    //等待中 且操作已在队列中 则无需恢复
    if (model.status == kHJDownloadStatus_Waiting && model.operation) {
        return;
    }
    
    model.operation = [[HJDownloadOperation alloc] initWithDownloadModel:model andSession:self.backgroundSession];
    [self.queue addOperation:model.operation];

}



- (void)stopWithDownloadModel:(HJDownloadModel *)model{
   
    [self stopWithDownloadModel:model forAll:NO];
}



- (void)stopWithDownloadModel:(HJDownloadModel *)model forAll:(BOOL)forAll{
    
    if (model.status != kHJDownloadStatus_Completed) {
        [model.operation cancel];
    }
    
    //移除对应的下载文件
    if([kFileManager fileExistsAtPath:model.destinationPath]){
        NSError *error = nil;
        [kFileManager removeItemAtPath:model.destinationPath error:&error];
        if (error) {
            NSLog(@"Tip:下载文件移除失败，%@",error);
        }else{
            NSLog(@"Tip:下载文件移除成功");
        }
    }
    
    //释放operation
    model.operation = nil;
    
    //单个删除 则直接从数组中移除下载模型 否则等清空文件后统一移除
    if(!forAll){
        [self.downloadModels removeObject:model];
    }
}


#pragma mark - 批量下载相关
/**
 *  批量下载操作
 */
- (void)startWithDownloadModels:(NSArray<HJDownloadModel *> *)downloadModels{
    NSLog(@">>>%@前 operationCount = %zd", NSStringFromSelector(_cmd),self.queue.operationCount);
    [self.queue setSuspended:NO];
    [self addDownloadModels:downloadModels];
    [self operateTasksWithOperationType:kHJOperationType_startAll];
    NSLog(@"<<<%@后 operationCount = %zd",NSStringFromSelector(_cmd),self.queue.operationCount);
}

/**
 *  暂停所有下载任务
 */
- (void)suspendAll{
    
    [self.queue setSuspended:YES];
    [self operateTasksWithOperationType:kHJOperationType_suspendAll];
}

/**
 *  恢复下载任务（进行中、已完成、等待中除外）
 */
- (void)resumeAll{
    
    [self.queue setSuspended:NO];
    [self operateTasksWithOperationType:kHJOperationType_resumeAll];
}

/**
 *  停止并删除下载任务
 */
- (void)stopAll{
    
    //销毁前暂停队列 防止等待中的任务执行
    [self.queue setSuspended:YES];
    [self.queue cancelAllOperations];
    [self operateTasksWithOperationType:kHJOperationType_stopAll];
    [self.queue setSuspended:NO];
    [self.downloadModels removeAllObjects];
    [self removeAllFiles];
}


- (void)operateTasksWithOperationType:(HJOperationType)operationType{
    
    [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        HJDownloadModel *downloadModel = obj;
        switch (operationType) {
            case kHJOperationType_startAll:
                [self startWithDownloadModel:downloadModel];
                break;
            case kHJOperationType_suspendAll:
                [self suspendWithDownloadModel:downloadModel forAll:YES];
                break;
            case kHJOperationType_resumeAll:
                [self resumeWithDownloadModel:downloadModel];
                break;
            case kHJOperationType_stopAll:
                [self stopWithDownloadModel:downloadModel forAll:YES];
                break;
            default:
                break;
        }
    }];
}


/**
 *  从备份恢复下载数据
 */
- (void)recoverDownloadModels{
    
    if ([kFileManager fileExistsAtPath:HJSavedDownloadModelsBackup]) {
        NSError * error = nil;
        [kFileManager removeItemAtPath:HJSavedDownloadModelsFilePath error:nil];
        BOOL recoverSuccess = [kFileManager copyItemAtPath:HJSavedDownloadModelsBackup toPath:HJSavedDownloadModelsFilePath error:&error];
        if (recoverSuccess) {
            NSLog(@"Tip:数据恢复成功");
            
            [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                HJDownloadModel *model = (HJDownloadModel *)obj;
                if (model.status == kHJDownloadStatus_Running ||
                    model.status == kHJDownloadStatus_Waiting){
                    [self startWithDownloadModel:model];
                }
            }];
        }else{
            NSLog(@"Tip:数据恢复失败，%@",error);
        }
    }
}

#pragma mark - 文件相关
/**
 *  保存下载模型
 */
- (void)saveData{
    
    [kFileManager removeItemAtPath:HJSavedDownloadModelsFilePath error:nil];
    BOOL flag = [NSKeyedArchiver archiveRootObject:self.downloadModels toFile:HJSavedDownloadModelsFilePath];
    NSLog(@"Tip:下载数据保存路径%@",HJSavedDownloadModelsFilePath);
    NSLog(@"Tip:下载数据保存-%@",flag?@"成功!":@"失败");
    
    if (flag) {
        [self backupFile];
    }
}
/**
 *  备份下载模型
 */
- (void)backupFile{
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSError *error = nil;
        [self removeBackupFile];
        BOOL exist = [kFileManager fileExistsAtPath:HJSavedDownloadModelsFilePath];
        if (exist) {
            BOOL backupSuccess = [kFileManager copyItemAtPath:HJSavedDownloadModelsFilePath toPath:HJSavedDownloadModelsBackup error:&error];
            if (backupSuccess) {
                NSLog(@"Tip:数据备份成功");
            }else{
                NSLog(@"Tip:数据备份失败，%@",error);
                [self backupFile];
            }
        }
    });
}
/**
 *  移除备份
 */
- (void)removeBackupFile{
    
    if ([kFileManager fileExistsAtPath:HJSavedDownloadModelsBackup]) {
        NSError * error = nil;
        BOOL success = [kFileManager removeItemAtPath:HJSavedDownloadModelsBackup error:&error];
        if (success) {
            NSLog(@"Tip:备份移除成功");
        }else{
            NSLog(@"Tip:备份移除失败，%@",error);
        }
    }
}

/**
 *  移除目录中所有文件
 */
- (void)removeAllFiles{
    
    //返回路径中的文件数组
    NSArray * files = [[NSFileManager defaultManager] subpathsAtPath:HJCachesDirectory];
    
    for(NSString *p in files){
        NSError*error;

        NSString*path = [HJCachesDirectory stringByAppendingString:[NSString stringWithFormat:@"/%@",p]];
        
        if([[NSFileManager defaultManager] fileExistsAtPath:path]){
            BOOL isRemove = [[NSFileManager defaultManager]removeItemAtPath:path error:&error];
            if(isRemove) {
                NSLog(@"文件：%@-->清除成功",p);
            }else{
                NSLog(@"文件：%@-->清除失败",p);
            }
        }
    }
}

#pragma mark - Private Method

#pragma mark - Getters/Setters
- (NSMutableArray *)downloadModels{
    
    if (!_downloadModels) {
        //查看本地是否有数据
        NSFileManager *fileManager = [NSFileManager defaultManager];
        BOOL exist = [fileManager fileExistsAtPath:HJSavedDownloadModelsFilePath isDirectory:nil];
        
        if (exist) {//有 则读取本地数据
            _downloadModels = [NSKeyedUnarchiver  unarchiveObjectWithFile:HJSavedDownloadModelsFilePath];
        }else{
            _downloadModels = [NSMutableArray array];
        }
    }
    return _downloadModels;
}

- (NSMutableArray *)completeModels{
    __block  NSMutableArray *tmpArr = [NSMutableArray array];
    if (self.downloadModels) {
        [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            HJDownloadModel *model = obj;
            if (model.status == kHJDownloadStatus_Completed) {
                [tmpArr addObject:model];
            }
        }];
    }
    
    _completeModels = tmpArr;
    return _completeModels;
}


- (NSMutableArray *)downloadingModels{
    __block  NSMutableArray *tmpArr = [NSMutableArray array];
    if (self.downloadModels) {
        [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            HJDownloadModel *model = obj;
            if (model.status == kHJDownloadStatus_Running) {
                [tmpArr addObject:model];
            }
        }];
    }
    
    _downloadingModels = tmpArr;
    return _downloadingModels;
}




- (NSMutableArray *)waitModels{
    __block  NSMutableArray *tmpArr = [NSMutableArray array];
    if (self.downloadModels) {
        [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            HJDownloadModel *model = obj;
            if (model.status == kHJDownloadStatus_Waiting) {
                [tmpArr addObject:model];
            }
        }];
    }
    return tmpArr;
}



- (NSMutableArray *)pauseModels{
    __block  NSMutableArray *tmpArr = [NSMutableArray array];
    if (self.downloadModels) {
        [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            HJDownloadModel *model = obj;
            if (model.status == kHJDownloadStatus_Suspended) {
                [tmpArr addObject:model];
            }
        }];
    }
    _pauseModels = tmpArr;
    return _pauseModels;
}



- (NSOperationQueue *)queue{
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
        [_queue setMaxConcurrentOperationCount:HJDownloadMaxConcurrentOperationCount];
    }
    return _queue;
}


- (void)setMaxConcurrentOperationCount:(NSInteger)maxConcurrentOperationCount{
    _maxConcurrentOperationCount = maxConcurrentOperationCount;
    self.queue.maxConcurrentOperationCount = _maxConcurrentOperationCount;
}


- (NSURLSession *)backgroundSession{
    if (!_backgroundSession) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
        //不能传self.queue
        _backgroundSession = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    
    return _backgroundSession;
}


- (BOOL)enableProgressLog{
    
    return _enableProgressLog;
}

#pragma mark - 后台任务相关
/**
 *  获取后台任务
 */
- (void)getBackgroundTask{
    
    NSLog(@"getBackgroundTask");
    UIBackgroundTaskIdentifier tempTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
    }];
    
    if (bgTask != UIBackgroundTaskInvalid) {
        
        [self endBackgroundTask];
    }
    
    bgTask = tempTask;
    
    [self performSelector:@selector(getBackgroundTask) withObject:nil afterDelay:120];
}


/**
 *  结束后台任务
 */
- (void)endBackgroundTask{
    
    [[UIApplication sharedApplication] endBackgroundTask:bgTask];
    bgTask = UIBackgroundTaskInvalid;
}



#pragma mark - Event Response
/**
 *  应用强关或闪退时 保存下载数据
 */
- (void)applicationWillTerminate{
    
    [self saveData];
}


#pragma mark - NSURLSessionDataDelegate
/**
 * 接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    
    HJDownloadModel *downloadModel = dataTask.downloadModel;
    
    // 打开流
    [downloadModel.stream open];
    
    // 获得服务器这次请求 返回数据的总长度
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + downloadModel.fileDownloadSize;
    downloadModel.fileTotalSize = totalLength;
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    
    NSLog(@"还在执行！");
    if (!dataTask.downloadModel) {
        return;
    }
    
    HJDownloadModel *downloadModel = dataTask.downloadModel;
    
    // 写入数据
    [downloadModel.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSInteger totalBytesWritten = downloadModel.fileDownloadSize;
    NSInteger totalBytesExpectedToWrite = downloadModel.fileTotalSize;
    
    double byts = totalBytesWritten * 1.0 / 1024 /1024;
    double total = totalBytesExpectedToWrite * 1.0 / 1024 /1024;
    NSString *text = [NSString stringWithFormat:@"%.1lfMB/%.1lfMB",byts,total];
    
    CGFloat progress = 1.0 * byts / total;
    
    downloadModel.statusText = text;
    downloadModel.progress = progress;
}

/**
 * 请求完毕 下载成功 | 失败
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    HJDownloadModel *downloadModel = task.downloadModel;
    [downloadModel.stream close];
    downloadModel.stream = nil;
    task = nil;
}
@end

