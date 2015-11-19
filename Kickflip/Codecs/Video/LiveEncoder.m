//
//  LXCaptureSession.m
//  
//
//  Created by Daniel Pourhadi on 10/22/15.
//
//

#import "LiveEncoder.h"
#import <AVFoundation/AVFoundation.h>
#import "VideoToolboxPlus.h"

@interface LiveEncoder () <VTPCompressionSessionDelegate>
@property (nonatomic, strong) VTPCompressionSession *session;
@property (nonatomic, strong) dispatch_queue_t queue;
@end

@implementation LiveEncoder

- (id)initWithHeight:(CGFloat)height width:(CGFloat)width bitrate:(CGFloat)bitRate {
    self = [super init];
    if (self) {
        NSError *error;
        self.session = [[VTPCompressionSession alloc] initWithWidth:width height:height codec:kCMVideoCodecType_H264 error:&error];
        if (error) {
            NSLog(@"encoder error - %@", error.localizedDescription);
        }
        
        self.queue = dispatch_queue_create("com.Lynxus.EncoderQueue", DISPATCH_QUEUE_SERIAL);
        [self.session setDelegate:self queue:self.queue];
        [self.session setAverageBitrate:bitRate error:&error];
        if (error) {
            NSLog(@"encoder error - %@", error.localizedDescription);
        }
        
        [self.session setProfileLevel:(NSString*)kVTProfileLevel_H264_Baseline_AutoLevel error:&error];
        if (error) {
            NSLog(@"encoder error - %@", error.localizedDescription);
        }
        
        [self.session setRealtime:YES error:&error];
        if (error) {
            NSLog(@"encoder error - %@", error.localizedDescription);
        }
        
        [self.session setAllowFrameReordering:NO error:&error];
        if (error) {
            NSLog(@"encoder error - %@", error.localizedDescription);
        }
        
        [self.session setMaxKeyframeInterval:30 error:&error];
        if (error) {
            NSLog(@"encoder error - %@", error.localizedDescription);
        }
        
        [self.session prepare];
    }   
    return self;
}

- (BOOL)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    return [self.session encodeSampleBuffer:sampleBuffer forceKeyframe:NO];
}

- (BOOL)finish {
    return [self.session finish];
}

#pragma mark - delegate
- (void)videoCompressionSession:(VTPCompressionSession *)compressionSession didEncodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (self.delegate) {
        [self.delegate encoder:self didEncodeSampleBuffer:sampleBuffer];
    }
}

@end
