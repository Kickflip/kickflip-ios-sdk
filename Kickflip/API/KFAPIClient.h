//
//  KFAPIClient.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFEndpointResponse.h"
#import "AFNetworking.h"

@interface KFAPIClient : AFHTTPClient

+ (KFAPIClient*) sharedClient;

- (void) requestRecordingEndpoint:(void (^)(KFEndpointResponse *endpointResponse, NSError *error))endpointCallback;
- (void) requestNewUser:(void (^)(KFUser *newUser, NSError *error))userCallback;

@end
