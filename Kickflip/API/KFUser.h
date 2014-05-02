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
 *  Native user model based on Kickflip API responses. All user data within
 *  the public data will be queryable and assumed to be public information.
 */
@interface KFUser : MTLModel <MTLJSONSerializing>

///-------------------------------
/// @name Public Data
///-------------------------------

/**
 *  Username returned by the server
 */
@property (readonly, nonatomic, strong) NSString *username;

/**
 *  User's desired display name
 */
@property (readonly, nonatomic, strong) NSString *displayName;

/**
 *  URL to the user's avatar
 */
@property (readonly, nonatomic, strong) NSURL *avatarURL;

/**
 *  Any additional information you'd like to store with a user.
 *  This is publicly queryable so do not store sensitive information here.
 *  @note Must be JSON serializable!
 */
@property (nonatomic, strong) NSDictionary *extraInfo;

/**
 *  Kickflip.io app name
 */
@property (readonly, nonatomic, strong) NSString *appName;

///-------------------------------
/// @name Private Data for the Active User
///-------------------------------


/**
 *  Unique identifier (UUID) returned by the server. This is used as an
 *  authentication token for the API.
 *  @note Do not expose this publicly.
 */
@property (readonly, nonatomic, strong) NSString *uuid;

/**
 *  Password for active user's account. Stored in the iOS Keychain.
 */
@property (nonatomic, strong) NSString *password;

///-------------------------------
/// @name Setting the Active User
///-------------------------------

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
