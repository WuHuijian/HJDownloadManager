//
//  HJDownloadConst.h
//  HJDownloadManager
//
//  Created by WHJ on 2018/2/28.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#ifndef HJDownloadConst_h
#define HJDownloadConst_h


#define kFileManager [NSFileManager defaultManager]

// 缓存主目录
#define  HJCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"/WHJDownload/"]

#define  HJSavedDownloadModelsFilePath [HJCachesDirectory stringByAppendingFormat:@"HJSavedDownloadModels"]

#define  HJSavedDownloadModelsBackup [HJCachesDirectory stringByAppendingFormat:@"HJSavedDownloadModelsBackup"]


#define  hj_tmpDownloadBaseFilePath [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]


// 下载operation最大并发数
#define HJDownloadMaxConcurrentOperationCount  3


#endif /* HJDownloadConst_h */
