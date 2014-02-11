//
//  KFEncoder.h
//  Kickflip
//
//  Created by Christopher Ballinger on 2/11/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class KFEncoder;

@protocol KFEncoderDelegate <NSObject>
- (void) encoder:(KFEncoder*)encoder encodedData:(NSData*)data pts:(CMTime)pts;
@end

@interface KFEncoder : NSObject

@property (nonatomic, weak) id<KFEncoderDelegate> delegate;
@property (nonatomic) dispatch_queue_t callbackQueue;

- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end
