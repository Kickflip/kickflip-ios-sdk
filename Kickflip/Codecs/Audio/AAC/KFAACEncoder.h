//
//  AACEncoder.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/18/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "KFEncoder.h"

@interface KFAACEncoder : KFEncoder

@property (nonatomic) dispatch_queue_t encoderQueue;
@property (nonatomic) BOOL addADTSHeader;

- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer completionBlock:(void (^)(NSData *encodedData, CMTime presentationTimeStamp, NSError* error))completionBlock;

@end
