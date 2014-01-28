//
//  KFRecorder.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class KFRecorder;

@protocol KFRecorderDelegate <NSObject>
- (void) recorderDidStartRecording:(KFRecorder*)recorder;
- (void) recorderDidFinishRecording:(KFRecorder*)recorder;
@end

@interface KFRecorder : NSObject

@property (nonatomic, weak) id<KFRecorderDelegate> delegate;

- (void) startRecording;
- (void) stopRecording;
- (AVCaptureVideoPreviewLayer*) previewLayer;


@end
