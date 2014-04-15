//
//  KFUser.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/22/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Mantle.h"

/**
 *  Native user model based on Kickflip API responses
 */
@interface KFUser : MTLModel <MTLJSONSerializing>

/**
 *  Username returned by the server
 */
@property (readonly, nonatomic, strong) NSString *username;

/**
 *  Unique identifier (UUID) returned by the server. This is used as an
 *  authentication token for the API.
 */
@property (readonly, nonatomic, strong) NSString *uuid;

/**
 *  Kickflip.io app name
 */
@property (readonly, nonatomic, strong) NSString *appName;

/**
 *  Active KFUser for communication with API, stored in `NSUserDefaults`.
 *
 *  @return active user, or nil if not availible
 */
+ (instancetype) activeUser;

/**
 *  Store the active user to `NSUserDefaults`
 *
 *  @param user if this parameter is nil, it will remove the active user.
 */
+ (void) setActiveUser:(KFUser*)user;

@end
