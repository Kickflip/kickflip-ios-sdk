//
//  AACEncoder.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/18/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "KFAudioEncoder.h"

@interface KFAACEncoder : KFAudioEncoder <KFSampleBufferEncoder>

@property (nonatomic) dispatch_queue_t encoderQueue;
@property (nonatomic) BOOL addADTSHeader;

@end
