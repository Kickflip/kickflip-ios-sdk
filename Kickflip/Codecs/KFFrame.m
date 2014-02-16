//
//  KFFrame.m
//  Kickflip
//
//  Created by Christopher Ballinger on 2/16/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFFrame.h"

@implementation KFFrame

- (id) initWithData:(NSData*)data pts:(CMTime)pts {
    if (self = [super init]) {
        _data = data;
        _pts = pts;
    }
    return self;
}

@end
