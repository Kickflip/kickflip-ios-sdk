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
 * Requests a new user.
 */
- (void) requestNewActiveUserWithUsername:(NSString*)username callbackBlock:(void (^)(KFUser *activeUser, NSError *error))callbackBlock;

/**
 * Returns all the streams created by a particular username
 */
- (void) requestStreamsForUsername:(NSString*)username callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock;

/**
 * Returns all the streams created near a certain location
 */
- (void) requestStreamsForLocation:(CLLocation*)location radius:(CLLocationDistance)radius callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock;

/**
 * Returns all the streams with metadata containing keyword
 * @param keyword (Optional) If this parameter is omitted it will return all streams
 */
- (void) requestStreamsByKeyword:(NSString*)keyword callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock;

/**
 * Returns all the streams associated with this application.
 */
- (void) requestAllStreams:(void (^)(NSArray *streams, NSError *error))callbackBlock;

@end
