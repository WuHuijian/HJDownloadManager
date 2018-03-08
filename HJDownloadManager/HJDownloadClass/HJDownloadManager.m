//
//  HJDownloadManager.m
//  HJNetworkService
//
//  Created by WHJ on 16/7/5.
//  Copyright © 2016年 WHJ. All rights reserved.
//

#import "HJDownloadManager.h"
#import "AppDelegate.h"

@interface HJDownloadManager ()<NSURLSessionDataDelegate>{
    NSMutableArray *_downloadModels;
    NSMutableArray *_completeModels;
    NSMutableArray *_downloadingModels;
    NSMutableArray *_pauseModels;
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
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(endBackgroundTask) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:instace selector:@selector(getBackgroundTask) name:UIApplicationDidEnterBackgroundNotification object:nil];
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

#pragma mark - 下载控制
- (void)addDownloadModel:(HJDownloadModel *)model{
    if (![self checkExistWithDownloadModel:model]) {
        [self.downloadModels addObject:model];
        NSLog(@"下载模型添加成功");
    }
}


- (void)addDownloadModels:(NSArray<HJDownloadModel *> *)models{
    if ([models isKindOfClass:[NSArray class]]) {
        [models enumerateObjectsUsingBlock:^(HJDownloadModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            HJDownloadModel *downloadModel = obj;
            if (![self checkExistWithDownloadModel:downloadModel]) {
                [self.downloadModels addObject:downloadModel];
            }
        }];
    }
}



- (void)startWithDownloadModel:(HJDownloadModel *)model{

    if (model.status == kHJDownloadStatusCompleted) {
        return;
    }
    
    [self addDownloadModel:model];
    
    [model setOperation:nil];
    
    __weak typeof(self) weakSelf = self;
    
    if (model.operation == nil) {
        model.operation = [[HJDownloadOperation alloc] initWithDownloadModel:model andSession:self.backgroundSession];
        model.operation.downloadStatusChangedBlock = ^{
            [weakSelf saveData];
        };
        [self.queue addOperation:model.operation];
        
    }else{
        
        if (model.operation.downloadStatusChangedBlock) {
            model.operation.session = self.backgroundSession;
            model.operation.downloadStatusChangedBlock = ^{
                [weakSelf saveData];
            };
        }
        [model.operation resume];
    }
}

- (void)suspendWithDownloadModel:(HJDownloadModel *)model{
    if (model.status == kHJDownloadStatus_Running || model.status == kHJDownloadStatusWaiting) {
        [model.operation suspend];
    }
}


- (void)resumeWithDownloadModel:(HJDownloadModel *)model{
   
    if (model.status != kHJDownloadStatus_suspended) {
        return;
    }
    
    [model setOperation:nil];
    
    __weak typeof(self) weakSelf = self;
   
    if (model.operation == nil) {
        model.operation = [[HJDownloadOperation alloc] initWithDownloadModel:model andSession:self.backgroundSession];
        model.operation.downloadStatusChangedBlock = ^{
            [weakSelf saveData];
        };
        [self.queue addOperation:model.operation];
        
    }else{
        
        if (model.operation.downloadStatusChangedBlock) {
            model.operation.session = self.backgroundSession;
            model.operation.downloadStatusChangedBlock = ^{
                [weakSelf saveData];
            };
        }
        [model.operation resume];
    }
}

- (void)stopWithDownloadModel:(HJDownloadModel *)model{
    
    if (model.status != kHJDownloadStatusCompleted) {
        
        [model.operation cancel];
    }
    
    [self removeDownloadModelWithModel:model];
}



- (void)startWithDownloadModels:(NSArray<HJDownloadModel *> *)downloadModels{
    
    [self addDownloadModels:downloadModels];
    
    [self operateTasksWithOperationType:kHJOperationType_startAll];
}



- (void)suspendAll{
    
    [self operateTasksWithOperationType:kHJOperationType_suspendAll];
}



- (void)resumeAll{
    
    [self operateTasksWithOperationType:kHJOperationType_resumeAll];
}



- (void)stopAll{
    
//    [self operateTasksWithOperationType:kHJOperationType_stopAll];
    [self.queue cancelAllOperations];
    [self.downloadModels removeAllObjects];
    [self removeAllFiles];
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
                    model.status == kHJDownloadStatusWaiting){
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

- (void)removeDownloadModelWithModel:(HJDownloadModel *)downloadModel{

        NSError *error = nil;
    
        [kFileManager removeItemAtPath:downloadModel.destinationPath error:&error];
        if (error) {
            NSLog(@"Tip:下载文件移除失败，%@",error);
        }else{
            NSLog(@"Tip:下载文件移除成功");
        }
        [self.downloadModels removeObject:downloadModel];
    
        [self saveData];
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
- (void)operateTasksWithOperationType:(HJOperationType)operationType{
    __weak typeof(self) weakSelf = self;
    [self.downloadModels enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        HJDownloadModel *downloadModel = obj;
        switch (operationType) {
            case kHJOperationType_startAll:
                [weakSelf startWithDownloadModel:downloadModel];
                break;
            case kHJOperationType_suspendAll:
                [weakSelf suspendWithDownloadModel:downloadModel];
                break;
            case kHJOperationType_resumeAll:
                [weakSelf startWithDownloadModel:downloadModel];
                break;
            case kHJOperationType_stopAll:
          
                break;
            default:
                break;
        }
    }];
}

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
            if (model.status == kHJDownloadStatusCompleted) {
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
            if (model.status == kHJDownloadStatusWaiting) {
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
            if (model.status == kHJDownloadStatus_suspended) {
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
    
    [self saveData];
    // 接收这个请求，允许接收服务器的数据
    
    completionHandler(NSURLSessionResponseAllow);
}

/**
 * 接收到服务器返回的数据
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    
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


@end

