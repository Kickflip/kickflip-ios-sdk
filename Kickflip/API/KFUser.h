//
//  KFUser.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/22/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KFUser : NSObject

@property (readonly, nonatomic, strong) NSString *username;
@property (readonly, nonatomic, strong) NSString *awsSecretKey;
@property (readonly, nonatomic, strong) NSString *awsAccessKey;
@property (readonly, nonatomic, strong) NSString *appName;

+ (instancetype) activeUser;
+ (instancetype) activeUserWithDictionary:(NSDictionary*)dictionary;
+ (void) deactivateUser;

@end
