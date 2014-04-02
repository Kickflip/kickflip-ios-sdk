//
//  KFBroadcastViewController.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KFRecorder.h"
#import "Kickflip.h"
#import "KFRecordButton.h"

@interface KFBroadcastViewController : UIViewController <KFRecorderDelegate>

@property (nonatomic, copy) KFBroadcastReadyBlock readyBlock;
@property (nonatomic, copy) KFBroadcastCompletionBlock completionBlock;

@property (strong, nonatomic) UIView *cameraView;
@property (nonatomic, strong) UIButton *shareButton;
@property (nonatomic, strong) KFRecordButton *recordButton;
@property (nonatomic, strong) UIImageView *liveBanner;

@property (nonatomic, strong) KFRecorder *recorder;
@property (nonatomic, strong) NSURL *shareURL;

@property (nonatomic, strong) UILabel *rotationLabel;
@property (nonatomic, strong) UIButton *cancelButton;

@end
