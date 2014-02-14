//
//  KFBroadcastViewController.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>

@class KFRecorder;

@interface KFBroadcastViewController : UIViewController

@property (strong, nonatomic) UIView *cameraView;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) UIButton *doneButton;
@property (nonatomic, strong) UIButton *startButton;
@property (nonatomic, strong) KFRecorder *recorder;

@end
