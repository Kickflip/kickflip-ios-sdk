//
//  KFRTMPEndpoint.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFStream.h"

@interface KFRTMPStream : KFStream

@property (nonatomic, strong) NSURL *rtmpURL;

@end
