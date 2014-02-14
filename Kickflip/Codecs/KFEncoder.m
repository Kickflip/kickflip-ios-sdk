//
//  KFEncoder.m
//  Kickflip
//
//  Created by Christopher Ballinger on 2/11/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFEncoder.h"

@implementation KFEncoder

- (id) init {
    if (self = [super init]) {
        self.callbackQueue = dispatch_queue_create("KF Encoder Callback Queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void) encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    
}

@end
