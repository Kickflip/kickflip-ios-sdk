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


/**
 * Fetches the currently active user or requests a new one if one is not found.
 */
- (void) fetchActiveUser:(void (^)(KFUser* activeUser, NSError* error))callbackBlock;

/**
 * Requests a new user.
 */
- (void) requestNewActiveUserWithUsername:(NSString*)username callbackBlock:(void (^)(KFUser *activeUser, NSError *error))callbackBlock;

/**
 * Returns the active user or fetches a new one.
 */
- (void) requestStreamsForUsername:(NSString*)username callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock;

- (void) requestStreamsForLocation:(CLLocation*)location radius:(CLLocationDistance)radius callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock;


@end
