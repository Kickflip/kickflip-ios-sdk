//
//  KFOnboardingViewController.h
//  Kickflip
//
//  Created by Christopher Ballinger on 6/13/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BButton;

@interface KFOnboardingViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView *logoImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UITextView *introductionTextView;
@property (strong, nonatomic) IBOutlet BButton *dismissButton;

- (IBAction)dismissButtonPressed:(id)sender;

@end
