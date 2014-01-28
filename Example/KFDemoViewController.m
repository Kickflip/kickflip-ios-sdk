//
//  KFDemoViewController.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/28/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFDemoViewController.h"
#import "Kickflip.h"

@interface KFDemoViewController ()
@property (nonatomic, strong, readwrite) UIButton *broadcastButton;
@end

@implementation KFDemoViewController

- (id) init {
    if (self = [super init]) {
        self.broadcastButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.broadcastButton addTarget:self action:@selector(broadcastButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self.broadcastButton setTitle:@"Broadcast" forState:UIControlStateNormal];
    }
    return self;
}

- (void) broadcastButtonPressed:(id)sender {
    [Kickflip presentBroadcasterFromViewController:self ready:^(NSURL *streamURL, NSError *error) {
        if (streamURL) {
            NSLog(@"Stream is ready at URL: %@", streamURL);
        } else {
            NSLog(@"Error setting up stream: %@", error);
        }
    } completion:^{
        NSLog(@"KF completion");
    }];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	[self.view addSubview:self.broadcastButton];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.broadcastButton.frame = CGRectMake(0, 0, 200, 100);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
