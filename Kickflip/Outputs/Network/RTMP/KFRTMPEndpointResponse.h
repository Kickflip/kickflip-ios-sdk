//
//  KFRTMPEndpointResponse.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFEndpointResponse.h"

@interface KFRTMPEndpointResponse : KFEndpointResponse

@property (nonatomic, strong, readonly) NSURL *rtmpURL;

@end
