//
//  HJDownloadHomeCell.h
//  HJDownloadManager
//
//  Created by WHJ on 2018/2/27.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HJBaseDownloadCell.h"

@class HJExampleModel;
@interface HJDownloadHomeCell : HJBaseDownloadCell

@property (nonatomic, strong) HJExampleModel *model;

+ (CGFloat)backCellHeight;

@end
