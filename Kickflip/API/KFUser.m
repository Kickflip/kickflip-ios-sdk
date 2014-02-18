//
//  KFUser.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/22/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFUser.h"
#import "KFLog.h"

static NSString * const KFUserUsernameKey = @"KFUserUsernameKey";
static NSString * const KFUserUUIDKey = @"KFUserUUIDKey";
static NSString * const KFUserAppNameKey = @"KFUserAppNameKey";

@interface KFUser()
@property (readwrite, nonatomic, strong) NSString *username;
@property (readwrite, nonatomic, strong) NSString *uuid;
@property (readwrite, nonatomic, strong) NSString* appName;
@end

@implementation KFUser

+ (instancetype) activeUser {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:KFUserUsernameKey];
    if (!username) {
        return nil;
    }
    NSString *uuid = [defaults objectForKey:KFUserUUIDKey];
    if (!uuid) {
        return nil;
    }
    
    KFUser *user = [[KFUser alloc] init];
    user.username = username;
    user.uuid = uuid;
    user.appName = [defaults objectForKey:KFUserAppNameKey];
    return user;
}

+ (instancetype) activeUserWithDictionary:(NSDictionary*)dictionary {
    [self deactivateUser];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = dictionary[@"name"];
    if (!username) {
        DDLogError(@"username is nil!");
        return nil;
    }
    NSString *uuid = dictionary[@"uuid"];
    if (!uuid) {
        DDLogInfo(@"uuid is nil!");
        return nil;
    }
    [defaults setObject:username forKey:KFUserUsernameKey];
    [defaults setObject:uuid forKey:KFUserUUIDKey];
    
    NSString *appName = dictionary[@"app"];
    if (appName) {
        [defaults setObject:appName forKey:KFUserAppNameKey];
    }
    
    [defaults synchronize];
    return [self activeUser];
}

+ (void) deactivateUser {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:KFUserUsernameKey];
    [defaults removeObjectForKey:KFUserUUIDKey];
    [defaults removeObjectForKey:KFUserAppNameKey];
    [defaults synchronize];
}

@end
