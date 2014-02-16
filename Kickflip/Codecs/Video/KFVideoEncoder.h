//
//  KFVideoEncoder.h
//  Kickflip
//
//  Created by Christopher Ballinger on 2/16/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFEncoder.h"

@interface KFVideoEncoder : KFEncoder

@property (nonatomic, readonly) NSUInteger width;
@property (nonatomic, readonly) NSUInteger height;

- (instancetype) initWithBitrate:(NSUInteger)bitrate width:(int)width height:(int)height;

@end
