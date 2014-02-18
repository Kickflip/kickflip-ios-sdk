//
//  KFAPIClient.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFEndpoint.h"
#import "AFNetworking.h"

@interface KFAPIClient : AFHTTPClient

+ (KFAPIClient*) sharedClient;

- (void) requestNewEndpoint:(void (^)(KFEndpoint *newEndpoint, NSError *error))endpointCallback;
- (void) requestNewUserWithUsername:(NSString*)username callbackBlock:(void (^)(KFUser *newUser, NSError *error))callbackBlock;

@end
