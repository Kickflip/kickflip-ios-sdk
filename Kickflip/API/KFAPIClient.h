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
#import <CoreLocation/CoreLocation.h>

@interface KFAPIClient : AFHTTPClient

+ (KFAPIClient*) sharedClient;

- (void) startNewStream:(void (^)(KFStream *newStream, NSError *error))endpointCallback;
- (void) stopStream:(KFStream*)stream callbackBlock:(void (^)(BOOL success, NSError *error))callbackBlock;

- (void) requestNewUserWithUsername:(NSString*)username callbackBlock:(void (^)(KFUser *newUser, NSError *error))callbackBlock;

// Server error
- (void) requestStreamsForUsername:(NSString*)username user:(KFUser*)user callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock;

- (void) requestStreamsForLocation:(CLLocation*)location radius:(CLLocationDistance)radius user:(KFUser*)user callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock;


@end
