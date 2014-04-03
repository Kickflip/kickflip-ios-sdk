//
//  KFUser.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/22/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

extern const struct KFUserAttributes {
	__unsafe_unretained NSString *username;
	__unsafe_unretained NSString *uuid;
	__unsafe_unretained NSString *appName;
} KFUserAttributes;

@interface KFUser : NSObject <NSSecureCoding>

@property (readonly, nonatomic, strong) NSString *username;
@property (readonly, nonatomic, strong) NSString *uuid;
@property (readonly, nonatomic, strong) NSString *appName;

+ (instancetype) activeUser;
+ (void) setActiveUser:(KFUser*)user;

- (instancetype) initWithJSONDictionary:(NSDictionary*)dictionary;

@end
