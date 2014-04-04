//
//  KFUser.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/22/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTLModel+NSCoding.h"
#import "MTLJSONAdapter.h"

extern const struct KFUserAttributes {
	__unsafe_unretained NSString *username;
	__unsafe_unretained NSString *uuid;
	__unsafe_unretained NSString *appName;
} KFUserAttributes;

@interface KFUser : MTLModel <MTLJSONSerializing>

@property (readonly, nonatomic, strong) NSString *username;
@property (readonly, nonatomic, strong) NSString *uuid;
@property (readonly, nonatomic, strong) NSString *appName;

+ (instancetype) activeUser;
+ (void) setActiveUser:(KFUser*)user;

@end
