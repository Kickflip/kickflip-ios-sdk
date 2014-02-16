//
//  KFAudioEncoder.m
//  Kickflip
//
//  Created by Christopher Ballinger on 2/16/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFAudioEncoder.h"

@implementation KFAudioEncoder

- (instancetype) initWithBitrate:(NSUInteger)bitrate sampleRate:(NSUInteger)sampleRate channels:(NSUInteger)channels {
    if (self = [super initWithBitrate:bitrate]) {
        self.sampleRate = sampleRate;
        self.channels = channels;
    }
    return self;
}

@end
