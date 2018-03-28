//
//  HJDownloadHome_VC.m
//  HJDownloadManager
//
//  Created by WHJ on 2018/2/27.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#import "HJDownloadHome_VC.h"
#import "HJDownloadHomeCell.h"
#import "HJExampleModel.h"
#import "HJDownloadManager.h"

@interface HJDownloadHome_VC ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *homeTable;

@property (nonatomic, strong) NSMutableArray *datas;

@property (nonatomic, strong) UIButton *tableHeader;

@end

static NSString * const kHJHomeTableCellID = @"HJHomeTableCellIdentifier";

@implementation HJDownloadHome_VC
#pragma mark - Life Circle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self buildData];
    
    [self setupUI];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)buildData{
    
    NSArray *urls = @[@"http://sw.bos.baidu.com/sw-search-sp/software/4ea1aa9dfac30/QQ_mac_6.2.1.dmg",
                      @"http://sw.bos.baidu.com/sw-search-sp/software/034dd6ef7b5fd/QQMusicMac_5.3.1.dmg",
                      @"http://sw.bos.baidu.com/sw-search-sp/software/5a442685f4f80/kwplayer_mac_1.4.0.pkg",
                      @"http://sw.bos.baidu.com/sw-search-sp/software/5e77ab765868f/NeteaseMusic_mac_1.5.9.622.dmg",
                      @"http://sw.bos.baidu.com/sw-search-sp/software/b3282eadef1fd/Kugou_mac_2.0.2.dmg"];
    NSArray *names = @[@"QQ.dmg",@"QQ音乐.dmg",@"酷我音乐.dmg",@"网易云.dmg",@"酷狗音乐.dmg"];
    
    NSMutableArray *datas = [NSMutableArray arrayWithCapacity:urls.count];
    self.datas = datas;
    [urls enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        HJExampleModel *model = [[HJExampleModel alloc] init];
        model.url = obj;
        model.name = names[idx];
        [datas addObject:model];
    }];
    
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if(!self.datas){
        [self buildData];
    }
    [self.homeTable reloadData];
}

#pragma mark - About UI
- (void)setupUI{
    
    UITableView *tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.estimatedRowHeight = 0.f;
    tableView.estimatedSectionHeaderHeight = 0.f;
    tableView.estimatedSectionFooterHeight = 0.f;
    [tableView registerClass:[HJDownloadHomeCell class] forCellReuseIdentifier:kHJHomeTableCellID];
    [self.view addSubview:tableView];
    
    self.homeTable = tableView;
    self.homeTable.tableHeaderView = self.tableHeader;
    
    
    UIButton * monitorBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [monitorBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    monitorBtn.frame = CGRectMake(0, 0, 80, 44);
    monitorBtn.titleLabel.font = [UIFont systemFontOfSize:16.f];
    [monitorBtn setTitle:@"闪退模拟" forState:UIControlStateNormal];
    monitorBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [monitorBtn addTarget:self action:@selector(monitorFlashAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc] initWithCustomView:monitorBtn];
    self.navigationItem.rightBarButtonItem = rightBarItem;
}

#pragma mark - Request Data

#pragma mark - Pravite Method

#pragma mark - Public Method

#pragma mark - Event response
- (void)downloadAll{
    
    NSMutableArray *models = [NSMutableArray arrayWithCapacity:self.datas.count];
    [self.datas enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        HJExampleModel *exampleModel = obj;
        HJDownloadModel *model = [[HJDownloadModel alloc] init];
        model.urlString = exampleModel.url;
        model.downloadDesc = exampleModel.name;
        [models addObject:model];
    }];
    
    [kHJDownloadManager startWithDownloadModels:models];
    //下载任务不是从cell中添加，所以需要刷新列表
    [self.homeTable reloadData];
}

- (void)monitorFlashAction{
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSArray *arr = @[];
            NSLog(@"%@",arr[1]);
    });
}
#pragma mark - Delegate methods

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    HJDownloadHomeCell *cell = [tableView dequeueReusableCellWithIdentifier:kHJHomeTableCellID];
    cell.model = self.datas[indexPath.row];
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    
    return 1;
}


#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    
    return nil;
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    return nil;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return [HJDownloadHomeCell backCellHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    
    return 0.001f;
}


#pragma mark - Getters/Setters/Lazy
- (UIButton *)tableHeader{
    
    if (!_tableHeader) {
        _tableHeader = [UIButton buttonWithType:UIButtonTypeSystem];
        [_tableHeader setFrame:CGRectMake(0, 0, 0, 44)];
        [_tableHeader addTarget:self action:@selector(downloadAll) forControlEvents:UIControlEventTouchUpInside];
        [_tableHeader setTitle:@"下载全部" forState:UIControlStateNormal];
        [_tableHeader setBackgroundColor:[UIColor lightGrayColor]];
    }
    return _tableHeader;
}
@end
