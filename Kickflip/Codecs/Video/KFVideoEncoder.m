//
//  KFVideoEncoder.m
//  Kickflip
//
//  Created by Christopher Ballinger on 2/16/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFVideoEncoder.h"

@implementation KFVideoEncoder

- (instancetype) initWithBitrate:(NSUInteger)bitrate width:(int)width height:(int)height {
    if (self = [super initWithBitrate:bitrate]) {
        _width = width;
        _height = height;
    }
    return self;
}

@end
