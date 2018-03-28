//
//  HJUncaughtExceptionHandler.h
//  HJDownloadManager
//
//  Created by WHJ on 2018/3/27.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HJUncaughtExceptionHandler : NSObject

+ (void)setDefaultHandler;
+ (NSUncaughtExceptionHandler *)getHandler;
+ (void)TakeException:(NSException *) exception;

@end
