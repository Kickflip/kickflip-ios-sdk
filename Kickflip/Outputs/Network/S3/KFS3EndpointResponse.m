//
//  KFS3EndpointResponse.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFS3EndpointResponse.h"
#import "KFUser.h"

@interface KFS3EndpointResponse()
@property (nonatomic, strong, readwrite) NSURL *broadcastURL;
@property (nonatomic, strong, readwrite) KFUser *user;
@property (nonatomic, strong, readwrite) NSString *uuid;

@end

@implementation KFS3EndpointResponse
@synthesize broadcastURL = _broadcastURL;
@synthesize user = _user;
@synthesize uuid = _uuid;

+ (instancetype) endpointResponseForUser:(KFUser*)user {
    KFS3EndpointResponse *response = [[KFS3EndpointResponse alloc] init];
    response.user = user;
    response.uuid = [[NSUUID UUID] UUIDString];
    
    NSString *broadcastURLString = [NSString stringWithFormat:@"http://%@.s3.amazonaws.com/%@/%@/index.m3u8", user.appName, user.username, response.uuid]; // this should probably be done somewhere else
    response.broadcastURL = [NSURL URLWithString:broadcastURLString];
    return response;
}

@end
