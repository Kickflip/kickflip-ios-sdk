//
//  KFBroadcastViewController.m
//  Encoder Demo
//
//  Created by Geraint Davies on 11/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "KFBroadcastViewController.h"
#import "KFRecorder.h"
#import "KFAPIClient.h"
#import "KFUser.h"
#import "KFLog.h"

@implementation KFBroadcastViewController

- (id) init {
    if (self = [super init]) {
        _cameraView = [[UIView alloc] init];
        _cameraView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _shareButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_shareButton setTitle:@"Share" forState:UIControlStateNormal];
        self.shareButton.enabled = NO;
        
        self.recordButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [self.recordButton setTitle:@"Start" forState:UIControlStateNormal];
        [self.recordButton addTarget:self action:@selector(recordButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        self.recorder = [[KFRecorder alloc] init];
        self.recorder.delegate = self;
    }
    return self;
}


- (void) recordButtonPressed:(id)sender {
    self.recordButton.enabled = NO;
    if (!self.recorder.isRecording) {
        [self.recordButton setTitle:@"Stop" forState:UIControlStateNormal];
        [self.recorder startRecording];
    } else {
        [self.recorder stopRecording];
    }
}

- (void) shareButtonPressed:(id)sender {
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[self.recorder.stream.kickflipURL] applicationActivities:nil];
    
    UIActivityViewControllerCompletionHandler completionHandler = ^(NSString *activityType, BOOL completed) {
        NSLog(@"share activity: %@", activityType);
    };
    activityViewController.completionHandler = completionHandler;
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:_cameraView];
    [self.view addSubview:_shareButton];
    [self.view addSubview:self.recordButton];
    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _cameraView.frame = self.view.bounds;
    _shareButton.frame = CGRectMake(50, 100, 200, 30);
    _recordButton.frame = CGRectMake(50, 200, 200, 30);
    
    [self startPreview];
}


- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // this is not the most beautiful animation...
    AVCaptureVideoPreviewLayer* preview = self.recorder.previewLayer;
    preview.frame = self.cameraView.bounds;
    [[preview connection] setVideoOrientation:[self avOrientationForInterfaceOrientation:toInterfaceOrientation]];
}

- (AVCaptureVideoOrientation) avOrientationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            return AVCaptureVideoOrientationLandscapeLeft;
            break;
    }
}

- (void) startPreview
{
    AVCaptureVideoPreviewLayer* preview = self.recorder.previewLayer;
    [preview removeFromSuperlayer];
    preview.frame = self.cameraView.bounds;
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    [[preview connection] setVideoOrientation:[self avOrientationForInterfaceOrientation:orientation]];
    
    [self.cameraView.layer addSublayer:preview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) recorderDidStartRecording:(KFRecorder *)recorder error:(NSError *)error {
    self.recordButton.enabled = YES;
    if (error) {
        DDLogError(@"Error starting stream: %@", error.userInfo);
        NSDictionary *response = [error.userInfo objectForKey:@"response"];
        NSString *reason = nil;
        if (response) {
            reason = [response objectForKey:@"reason"];
        }
        NSMutableString *errorMsg = [NSMutableString stringWithFormat:@"Error starting stream: %@.", error.localizedDescription];
        if (reason) {
            [errorMsg appendFormat:@" %@", reason];
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Stream Start Error" message:errorMsg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alertView show];
        [self.recordButton setTitle:@"Start" forState:UIControlStateNormal];
    }
}

- (void) recorder:(KFRecorder *)recorder streamReadyAtURL:(NSURL *)url {
    self.shareButton.enabled = YES;
    if (_readyBlock) {
        _readyBlock(url);
    }
}

- (void) recorderDidFinishRecording:(KFRecorder *)recorder error:(NSError *)error {
    if (_completionBlock) {
        if (error) {
            _completionBlock(NO, error);
        } else {
            _completionBlock(YES, nil);
        }
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
