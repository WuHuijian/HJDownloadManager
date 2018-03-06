//
//  HJDownloadListCell.h
//  HJDownloadManager
//
//  Created by WHJ on 2018/2/28.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#import "HJBaseDownloadCell.h"

@class HJDownloadModel;
@interface HJDownloadListCell : HJBaseDownloadCell

@property (nonatomic, strong) HJDownloadModel *downloadModel;

+ (CGFloat)backCellHeight;

@end
