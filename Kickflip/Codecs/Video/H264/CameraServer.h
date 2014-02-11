//
//  CameraServer.h
//  Encoder Demo
//
//  Created by Geraint Davies on 19/02/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import <Foundation/Foundation.h>
#import "AVFoundation/AVCaptureSession.h"
#import "AVFoundation/AVCaptureOutput.h"
#import "AVFoundation/AVCaptureDevice.h"
#import "AVFoundation/AVCaptureInput.h"
#import "AVFoundation/AVCaptureVideoPreviewLayer.h"
#import "AVFoundation/AVMediaFormat.h"
#import "HLSUploader.h"
#import "KFH264Encoder.h"
@class HLSWriter;

@interface CameraServer : NSObject <KFEncoderDelegate>

+ (CameraServer*) server;
- (void) startup;
- (void) shutdown;
- (void) startBroadcast;
- (void) stopBroadcast;
- (NSString*) getURL;
- (AVCaptureVideoPreviewLayer*) getPreviewLayer;

@property (nonatomic, strong) HLSUploader *hlsUploader;
@property (nonatomic, strong) HLSWriter *hlsWriter;

@end
