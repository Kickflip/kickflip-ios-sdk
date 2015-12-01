//
//  KFH264Encoder.h
//  Kickflip
//
//  Created by Christopher Ballinger on 2/11/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//


#import "KFVideoEncoder.h"
#import "AVEncoder.h"

@interface KFH264Encoder : KFVideoEncoder <KFSampleBufferEncoder>

@property (nonatomic, strong) AVEncoder* encoder;
- (void)shutdown;

@end
