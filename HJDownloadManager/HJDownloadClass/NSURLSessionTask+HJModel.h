//
//  NSURLSessionTask+HJModel.h
//  HJNetworkService
//
//  Created by WHJ on 16/7/5.
//  Copyright © 2016年 WHJ. All rights reserved.
//

#import <Foundation/Foundation.h>
@class HJDownloadModel;

@interface NSURLSessionTask (HJModel)

@property (nonatomic, weak)HJDownloadModel  * downloadModel;

@end
