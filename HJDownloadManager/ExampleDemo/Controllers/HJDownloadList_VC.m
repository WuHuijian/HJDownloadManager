//
//  HJDownloadList_VC.m
//  HJDownloadManager
//
//  Created by WHJ on 2018/2/27.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#import "HJDownloadList_VC.h"
#import "HJDownloadListCell.h"
#import "HJDownloadManager.h"

@interface HJDownloadList_VC ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *listTable;

@property (nonatomic, strong) NSMutableArray *datas;

@property (nonatomic, strong) UIView *tableHeader;

@end

static NSString * const kHJlistTableCellID = @"HJlistTableCellIdentifier";

@implementation HJDownloadList_VC
#pragma mark - Life Circle
- (void)viewDidLoad {
    [super viewDidLoad];

    [self setupUI];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)buildDatas{
    
    self.datas = [NSMutableArray arrayWithArray:[kHJDownloadManager downloadModels]];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self buildDatas];
    
    if(self.datas){
        self.listTable.editing = NO;
        [self.listTable reloadData];
    }
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
    [tableView registerClass:[HJDownloadListCell class] forCellReuseIdentifier:kHJlistTableCellID];
    [self.view addSubview:tableView];
    self.listTable = tableView;
    self.listTable.tableHeaderView = self.tableHeader;
    
    UIButton * deleteAllBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [deleteAllBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    deleteAllBtn.frame = CGRectMake(0, 0, 44, 44);
    deleteAllBtn.titleLabel.font = [UIFont systemFontOfSize:16.f];
    [deleteAllBtn setTitle:@"删除" forState:UIControlStateNormal];
    deleteAllBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [deleteAllBtn addTarget:self action:@selector(deleteAllAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc] initWithCustomView:deleteAllBtn];
    self.navigationItem.rightBarButtonItem = rightBarItem;
}




#pragma mark - Request Data

#pragma mark - Pravite Method

#pragma mark - Public Method

#pragma mark - Event response
- (void)deleteAllAction{
    
    UIAlertController *alertC = [[UIAlertController alloc] init];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"考虑一下" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认删除" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        
         [kHJDownloadManager stopAll];
         [self.datas removeAllObjects];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.listTable reloadData];
        });
    }];
    
    [alertC addAction:cancelAction];
    [alertC addAction:confirmAction];
    [self presentViewController:alertC animated:YES completion:nil] ;
}


- (void)pauseAll{
    
    [kHJDownloadManager suspendAll];
    
}


- (void)resumeAll{
    
    [kHJDownloadManager resumeAll];
}
#pragma mark - Delegate methods

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return self.datas.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    HJDownloadListCell *cell = [tableView dequeueReusableCellWithIdentifier:kHJlistTableCellID];
    cell.downloadModel = self.datas[indexPath.row];
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
    return [HJDownloadListCell backCellHeight];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    
    return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    
    return 0.001f;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath{
    
}



- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
   __weak HJDownloadListCell *weakCell = [tableView cellForRowAtIndexPath:indexPath];
    __weak typeof(self) weakSelf = self;
    
    UITableViewRowAction *action = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"删除" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [tableView beginUpdates];
        
        HJDownloadModel *downloadModel = weakCell.downloadModel;
        [kHJDownloadManager stopWithDownloadModel:weakSelf.datas[indexPath.row]];
        [weakSelf.datas removeObject:downloadModel];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationBottom];
       
        [tableView endUpdates];
    }];
    
    return @[action];
}


#pragma mark - Getters/Setters/Lazy
- (UIView *)tableHeader{
    
    if (!_tableHeader) {
        CGFloat width = self.view.frame.size.width;
        _tableHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, 44)];
        UIButton * pauseAllBtn = [self buttonWithTitle:@"暂停全部" action:@selector(pauseAll)];
        [pauseAllBtn setFrame:CGRectMake(0, 0,width/2.f, 44)];
        [_tableHeader addSubview:pauseAllBtn];
        
        UIButton * resumeAllBtn = [self buttonWithTitle:@"全部继续" action:@selector(resumeAll)];
        [resumeAllBtn setFrame:CGRectMake(width/2.f, 0,width/2.f, 44)];
        [_tableHeader addSubview:resumeAllBtn];

    }
    return _tableHeader;
}


- (UIButton *)buttonWithTitle:(NSString *)title action:(SEL)sel{
    
    UIButton * btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setBackgroundColor:[UIColor lightGrayColor]];
    return btn;
}
@end
