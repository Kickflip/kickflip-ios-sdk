//
//  KFAPIClient.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFStream.h"
#import "AFNetworking.h"

@interface KFAPIClient : AFHTTPClient

+ (KFAPIClient*) sharedClient;

- (void) startNewStream:(void (^)(KFStream *newStream, NSError *error))endpointCallback;
- (void) stopStream:(KFStream*)stream callbackBlock:(void (^)(BOOL success, NSError *error))callbackBlock;

- (void) requestNewUserWithUsername:(NSString*)username callbackBlock:(void (^)(KFUser *newUser, NSError *error))callbackBlock;

@end
