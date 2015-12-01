//
//  KFH264Encoder.m
//  Kickflip
//
//  Created by Christopher Ballinger on 2/11/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFH264Encoder.h"
#import "NALUnit.h"
#import "KFLog.h"
#import "KFVideoFrame.h"

@interface KFH264Encoder()
@property (nonatomic) CMTimeScale timescale;
@property (nonatomic) CMTime lastPTS;
@end

@implementation KFH264Encoder

- (void) dealloc {
    [_encoder shutdown];
}

- (void)shutdown {
    [_encoder encodeWithBlock:nil onParams:nil];
}

- (instancetype) initWithBitrate:(NSUInteger)bitrate width:(int)width height:(int)height {
    if (self = [super initWithBitrate:bitrate]) {
        _lastPTS = kCMTimeInvalid;
        _timescale = 0;
        
        _encoder = [AVEncoder encoderForHeight:height andWidth:width bitrate:bitrate];
        [_encoder encodeWithBlock:^int(EncodedDataWrapper* wrapper, CMTimeValue ptsValue) {
          [self incomingVideoFrames:wrapper ptsValue:ptsValue];
              return 0;
          } onParams:^int(NSData *data) {
              return 0;
          }];
        }
    return self;
}

- (void) setBitrate:(NSUInteger)bitrate {
    [super setBitrate:bitrate];
    _encoder.bitrate = self.bitrate;
}

- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    if (!_timescale) {
        _timescale = pts.timescale;
    }
    [_encoder encodeFrame:sampleBuffer];
}

- (void) writeVideoFrames:(EncodedDataWrapper*)wrapper pts:(CMTime)pts {
    if (self.delegate) {
        KFVideoFrame *videoFrame = [[KFVideoFrame alloc] initWithData:wrapper.data pts:pts];
        videoFrame.isKeyFrame = wrapper.isKeyFrame;
        dispatch_async(self.callbackQueue, ^{
            [self.delegate encoder:self encodedFrame:videoFrame];
        });
    }
}

- (void) incomingVideoFrames:(EncodedDataWrapper*)wrapper ptsValue:(CMTimeValue)ptsValue {
    CMTime pts = CMTimeMake(ptsValue, _timescale);
    [self writeVideoFrames:wrapper pts:pts];
    _lastPTS = pts;
}

@end
