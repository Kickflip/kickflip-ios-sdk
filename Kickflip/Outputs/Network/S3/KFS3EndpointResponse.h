//
//  KFS3EndpointResponse.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFEndpointResponse.h"

@class KFUser;

@interface KFS3EndpointResponse : KFEndpointResponse

+ (instancetype) endpointResponseForUser:(KFUser*)user;

@end
