//
//  KFRecordingViewController.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KFPreviewView.h"

@interface KFRecordingViewController : UIViewController

@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) KFPreviewView *previewView;

@end
