//
//  HJDownloadTabBar_VC.m
//  HJDownloadManager
//
//  Created by WHJ on 2018/2/27.
//  Copyright © 2018年 WHJ. All rights reserved.
//

#import "HJDownloadTabBar_VC.h"
#import "HJDownloadHome_VC.h"
#import "HJDownloadList_VC.h"

@interface HJDownloadTabBar_VC ()

@end

@implementation HJDownloadTabBar_VC

#pragma mark - Life Circle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupUI];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - About UI
- (void)setupUI{
    
    HJDownloadHome_VC *homeVC = [[HJDownloadHome_VC alloc] init];
    HJDownloadList_VC *listVC = [[HJDownloadList_VC alloc] init];
    
    UINavigationController *homeNav = [[UINavigationController alloc] initWithRootViewController:homeVC];
    
    UINavigationController *listNav = [[UINavigationController alloc] initWithRootViewController:listVC];
    
    homeNav.tabBarItem.title = @"下载首页";
    listNav.tabBarItem.title = @"下载列表";
    
    homeVC.title = @"下载首页";
    listVC.title = @"下载列表";
    
    self.viewControllers = @[homeNav,listNav];
    
}

#pragma mark - Request Data

#pragma mark - Pravite Method

#pragma mark - Public Method

#pragma mark - Event response

#pragma mark - Delegate methods

#pragma mark - Getters/Setters/Lazy

@end
