//
//  KFAudioEncoder.h
//  Kickflip
//
//  Created by Christopher Ballinger on 2/16/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFEncoder.h"

@interface KFAudioEncoder : KFEncoder

@property (nonatomic) NSUInteger sampleRate;
@property (nonatomic) NSUInteger channels;

- (instancetype) initWithBitrate:(NSUInteger)bitrate sampleRate:(NSUInteger)sampleRate channels:(NSUInteger)channels;

@end
