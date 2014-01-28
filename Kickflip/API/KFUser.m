//
//  KFUser.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/22/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFUser.h"
#import "SSKeychain.h"
#import "KFLog.h"

static NSString * const KFUsernameKey = @"KFUsernameKey";
static NSString * const KFKeychainServiceName = @"io.kickflip.keychainservice";
static NSString * const KFAWSAccessKey = @"KFAWSAccessKey";
static NSString * const KFAWSSecretKey = @"KFAWSSecretKey";
static NSString * const KFAppNameKey = @"KFAppNameKey";

@interface KFUser()
@property (readwrite, nonatomic, strong) NSString *username;
@property (readwrite, nonatomic, strong) NSString *awsSecretKey;
@property (readwrite, nonatomic, strong) NSString *awsAccessKey;
@property (readwrite, nonatomic, strong) NSString *appName;
@end

@implementation KFUser

+ (instancetype) activeUser {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = [defaults objectForKey:KFUsernameKey];
    if (!username) {
        return nil;
    }
    NSString *appName = [defaults objectForKey:KFAppNameKey];
    if (!appName) {
        return nil;
    }
    NSString *awsSecretKey = [SSKeychain passwordForService:KFKeychainServiceName account:KFAWSSecretKey];
    if (!awsSecretKey) {
        return nil;
    }
    NSString *awsAccessKey = [SSKeychain passwordForService:KFKeychainServiceName account:KFAWSAccessKey];
    if (!awsAccessKey) {
        return nil;
    }
    
    KFUser *user = [[KFUser alloc] init];
    user.username = username;
    user.awsAccessKey = awsAccessKey;
    user.awsSecretKey = awsSecretKey;
    user.appName = appName;
    return user;
}

+ (instancetype) activeUserWithDictionary:(NSDictionary*)dictionary {
    [self deactivateUser];
    [SSKeychain setAccessibilityType:kSecAttrAccessibleAfterFirstUnlock];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *username = dictionary[@"name"];
    if (!username) {
        DDLogError(@"username is nil!");
        return nil;
    }
    NSString *appName = dictionary[@"app"];
    if (!appName) {
        DDLogError(@"appName is nil!");
        return nil;
    }
    NSString *awsAccessKey = dictionary[@"aws_access_key"];
    if (!awsAccessKey) {
        DDLogError(@"awsAccessKey is nil!");
        return nil;
    }
    NSString *awsSecretKey = dictionary[@"aws_secret_key"];
    if (!awsSecretKey) {
        DDLogError(@"awsSecretKey is nil!");
        return nil;
    }
    [defaults setObject:username forKey:KFUsernameKey];
    [defaults setObject:appName forKey:KFAppNameKey];
    [defaults synchronize];
    
    [SSKeychain setPassword:awsAccessKey forService:KFKeychainServiceName account:KFAWSAccessKey];
    [SSKeychain setPassword:awsSecretKey forService:KFKeychainServiceName account:KFAWSSecretKey];
    
    return [self activeUser];
}

+ (void) deactivateUser {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:KFUsernameKey];
    [defaults removeObjectForKey:KFAppNameKey];
    [defaults synchronize];
    [SSKeychain deletePasswordForService:KFKeychainServiceName account:KFAWSAccessKey];
    [SSKeychain deletePasswordForService:KFKeychainServiceName account:KFAWSSecretKey];
}


@end
