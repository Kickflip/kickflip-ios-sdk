//
//  KFEncoder.m
//  Kickflip
//
//  Created by Christopher Ballinger on 2/16/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFEncoder.h"

@implementation KFEncoder

- (instancetype) initWithBitrate:(NSUInteger)bitrate {
    if (self = [super init]) {
        self.bitrate = bitrate;
        self.callbackQueue = dispatch_queue_create("KFEncoder Callback Queue", NULL);
    }
    return self;
}

@end