//
//  KFDemoViewController.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/28/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSPullToRefresh.h"

@interface KFDemoViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, SSPullToRefreshViewDelegate>

@property (nonatomic, strong) UITableView *streamsTableView;
@property (nonatomic, strong) SSPullToRefreshView *pullToRefreshView;

@end
