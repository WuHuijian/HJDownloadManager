//
//  NSURLSessionTask+HJModel.m
//  HJNetworkService
//
//  Created by WHJ on 16/7/5.
//  Copyright © 2016年 WHJ. All rights reserved.
//

#import "NSURLSessionTask+HJModel.h"
#import <objc/runtime.h>
#import "HJDownloadModel.h"
#import "MJExtension.h"


@implementation NSURLSessionTask (HJModel)

/**
 *  添加downloadModel属性
 */

static const void *hj_downloadModelKey = @"downloadModelKey";

- (void)setDownloadModel:(HJDownloadModel *)downloadModel{

    objc_setAssociatedObject(self, &hj_downloadModelKey, downloadModel, OBJC_ASSOCIATION_ASSIGN);
}


- (HJDownloadModel *)downloadModel{

    return objc_getAssociatedObject(self, &hj_downloadModelKey);
}


@end
