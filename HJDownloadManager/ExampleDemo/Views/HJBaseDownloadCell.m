//
//  HJBaseDownloadCell.m
//  HJDownloadManager
//
//  Created by WHJ on 2018/2/27.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#import "HJBaseDownloadCell.h"

@implementation HJBaseDownloadCell

#pragma mark - Life Circle
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        
        [self setupUI];
    }
    return self;
}


#pragma mark - About UI
- (void)setupUI{
    
    [self.contentView addSubview:self.titleLabel];
    
    [self.contentView addSubview:self.downloadBtn];
    
    [self.contentView addSubview:self.fileSizeLabel];
    
    [self.contentView addSubview:self.progressView];
}



#pragma mark - Pravite Method

#pragma mark - Public Method

#pragma mark - Event response
- (void)downloadAction:(UIButton *)sender{
    
    
}
#pragma mark - Delegate methods

#pragma mark - Getters/Setters/Lazy
- (UILabel *)titleLabel{
    
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont systemFontOfSize:14.f];
    }
    return _titleLabel;
}


- (UILabel *)fileSizeLabel{
    
    if (!_fileSizeLabel) {
        _fileSizeLabel = [[UILabel alloc] init];
        _fileSizeLabel.font = [UIFont systemFontOfSize:14.f];
    }
    return _fileSizeLabel;
}



- (UILabel *)fileFormatLabel{
    
    if (!_fileFormatLabel) {
        _fileFormatLabel = [[UILabel alloc] init];
        _fileFormatLabel.font = [UIFont systemFontOfSize:14.f];
        [self.contentView addSubview:_fileFormatLabel];
    }
    return _fileFormatLabel;
}


- (UIButton *)downloadBtn{
    
    if (!_downloadBtn) {
        _downloadBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_downloadBtn addTarget:self action:@selector(downloadAction:) forControlEvents:UIControlEventTouchUpInside];
        [_downloadBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        _downloadBtn.titleLabel.font = [UIFont systemFontOfSize:10];
    }
    return _downloadBtn;
}

- (UIProgressView *)progressView{
    
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] init];
    }
    return _progressView;
}
@end
