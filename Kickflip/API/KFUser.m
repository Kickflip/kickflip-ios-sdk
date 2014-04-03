//
//  KFUser.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/22/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFUser.h"
#import "KFLog.h"

const struct KFUserAttributes KFUserAttributes = {
	.username = @"username",
	.uuid = @"uuid",
	.appName = @"appName",
};

static NSString * const KFUserActiveUserKey = @"KFUserActiveUserKey";

@interface KFUser()
@property (readwrite, nonatomic, strong) NSString *username;
@property (readwrite, nonatomic, strong) NSString *uuid;
@property (readwrite, nonatomic, strong) NSString *appName;
@end

@implementation KFUser

- (instancetype) initWithJSONDictionary:(NSDictionary*)dictionary {
    if (self = [super init]) {
        self.username = dictionary[@"name"];
        self.uuid = dictionary[@"uuid"];
        self.appName = dictionary[@"app"];
    }
    return self;
}

+ (instancetype) activeUser {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedData = [defaults objectForKey:KFUserActiveUserKey];
    if (!encodedData) {
        return nil;
    }
    KFUser *user = [NSKeyedUnarchiver unarchiveObjectWithData:encodedData];
    return user;
}

+ (void) setActiveUser:(KFUser*)user {
    [self deactivateUser];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:user];
    [defaults setObject:encodedObject forKey:KFUserActiveUserKey];
    [defaults synchronize];
}


+ (void) deactivateUser {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:KFUserActiveUserKey];
    [defaults synchronize];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.username forKey:KFUserAttributes.username];
    [aCoder encodeObject:self.uuid forKey:KFUserAttributes.uuid];
    [aCoder encodeObject:self.appName forKey:KFUserAttributes.appName];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.username = [aDecoder decodeObjectOfClass:[NSString class] forKey:KFUserAttributes.username];
        self.uuid = [aDecoder decodeObjectOfClass:[NSString class] forKey:KFUserAttributes.uuid];
        self.appName = [aDecoder decodeObjectOfClass:[NSString class] forKey:KFUserAttributes.appName];
    }
    return self;
}

+ (BOOL) supportsSecureCoding {
    return YES;
}

@end
