//
//  EncoderDemoViewController.m
//  Encoder Demo
//
//  Created by Geraint Davies on 11/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "EncoderDemoViewController.h"
#import "CameraServer.h"
#import "HLSWriter.h"
#import "OWSecrets.h"
#import "KFAPIClient.h"
#import "KFUser.h"

@implementation EncoderDemoViewController

- (id) init {
    if (self = [super init]) {
        _cameraView = [[UIView alloc] init];
        _cameraView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _serverAddress = [[UILabel alloc] init];
        _shareButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        [_shareButton addTarget:self action:@selector(shareButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [_shareButton setTitle:@"Share" forState:UIControlStateNormal];
    }
    return self;
}

- (void) shareButtonPressed:(id)sender {
    NSString *kickflipURLString = [NSString stringWithFormat:@"http://kickflip.io/video.html?v=%@", [CameraServer server].hlsWriter.uuid];
    NSURL *kickflipURL = [NSURL URLWithString:kickflipURLString];
    NSURL *manifestURL = [CameraServer server].hlsUploader.manifestURL;
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[kickflipURL, manifestURL] applicationActivities:nil];
    
    UIActivityViewControllerCompletionHandler completionHandler = ^(NSString *activityType, BOOL completed) {
        NSLog(@"activity: %@", activityType);
    };
    
    activityViewController.completionHandler = completionHandler;
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:_cameraView];
    [self.view addSubview:_serverAddress];
    [self.view addSubview:_shareButton];
    
    [self startPreview];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _cameraView.frame = self.view.bounds;
    _serverAddress.frame = CGRectMake(50, 50, 200, 30);
    _shareButton.frame = CGRectMake(50, 100, 200, 30);
    
    [self testOAuthStuff];
}

- (void) testOAuthStuff {
    [[KFAPIClient sharedClient] requestRecordingEndpoint:^(KFEndpointResponse *endpointResponse, NSError *error) {
        if (!error) {
            NSLog(@"broadcast url: %@", endpointResponse.broadcastURL);
        } else {
            NSLog(@"error getting endpoint: %@", error);
        }
    }];
}



- (void) willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    // this is not the most beautiful animation...
    AVCaptureVideoPreviewLayer* preview = [[CameraServer server] getPreviewLayer];
    preview.frame = self.cameraView.bounds;
    [[preview connection] setVideoOrientation:toInterfaceOrientation];
}

- (void) startPreview
{
    AVCaptureVideoPreviewLayer* preview = [[CameraServer server] getPreviewLayer];
    [preview removeFromSuperlayer];
    preview.frame = self.cameraView.bounds;
    [[preview connection] setVideoOrientation:UIInterfaceOrientationPortrait];
    
    [self.cameraView.layer addSublayer:preview];
    
    self.serverAddress.text = [[CameraServer server] getURL];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
