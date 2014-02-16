//
//  KFEncoder.h
//  Kickflip
//
//  Created by Christopher Ballinger on 2/14/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class KFFrame, KFEncoder;

@protocol KFSampleBufferEncoder <NSObject>
- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

@protocol KFEncoderDelegate <NSObject>
- (void) encoder:(KFEncoder*)encoder encodedFrame:(KFFrame*)frame;
@end

@interface KFEncoder : NSObject

@property (nonatomic) NSUInteger bitrate;
@property (nonatomic) dispatch_queue_t callbackQueue;
@property (nonatomic, weak) id<KFEncoderDelegate> delegate;

- (instancetype) initWithBitrate:(NSUInteger)bitrate;

@end