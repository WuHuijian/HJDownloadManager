//
//  HJBaseDownloadCell.h
//  HJDownloadManager
//
//  Created by WHJ on 2018/2/27.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HJBaseDownloadCell : UITableViewCell

/** <#describe#> */
@property (nonatomic, strong) UILabel * titleLabel;

/** <#describe#> */
@property (nonatomic, strong) UIButton * downloadBtn;

/** <#describe#> */
@property (nonatomic, strong) UIProgressView * progressView;

/** <#describe#> */
@property (nonatomic, strong) UILabel *fileSizeLabel;

/** <#describe#> */
@property (nonatomic, strong) UILabel *fileFormatLabel;


- (void)downloadAction:(UIButton *)sender;

@end
