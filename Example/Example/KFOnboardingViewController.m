//
//  KFOnboardingViewController.m
//  Kickflip
//
//  Created by Christopher Ballinger on 6/13/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFOnboardingViewController.h"
#import "BButton.h"
#import "KFConstants.h"

@interface KFOnboardingViewController ()

@end

@implementation KFOnboardingViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.dismissButton setStyle:BButtonStyleBootstrapV3];
    [self.dismissButton setType:BButtonTypeDefault];
    
    UIColor *linkColor = [UIColor colorWithWhite:0.8 alpha:1.0];
    NSDictionary *linkTextAttributes = @{NSForegroundColorAttributeName: linkColor};
    self.introductionTextView.linkTextAttributes = linkTextAttributes;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)dismissButtonPressed:(id)sender {
    [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:KFHasCompletedOnboardingKey];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

@end
