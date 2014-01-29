//
//  KFEndpointResponse.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KFUser;

@interface KFEndpointResponse : NSObject

@property (nonatomic, strong, readonly) KFUser *user;
@property (nonatomic, strong, readonly) NSString *uuid;
@property (nonatomic, strong, readonly) NSURL *broadcastURL;

@end
