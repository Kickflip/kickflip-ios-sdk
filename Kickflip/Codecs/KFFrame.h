//
//  KFFrame.h
//  Kickflip
//
//  Created by Christopher Ballinger on 2/16/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface KFFrame : NSObject

@property (nonatomic, strong) NSData *data;
@property (nonatomic) CMTime pts;

- (instancetype) initWithData:(NSData*)data pts:(CMTime)pts;

@end
