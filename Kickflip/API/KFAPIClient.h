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

/**
 *  Use KFAPIClient to interact with the kickflip.io API
 */
@interface KFAPIClient : AFHTTPClient

/**
 *  Singleton for easy access around your project
 *
 *  @return KFAPIClient singleton
 */
+ (KFAPIClient*) sharedClient;


///-------------------------------
/// @name Users
///-------------------------------

/**
 *  Requests new active user.
 *
 *  @param username      (optional) desired username
 *  @param callbackBlock called when the request completes with either an active user or an error
 */
- (void) requestNewActiveUserWithUsername:(NSString*)username callbackBlock:(void (^)(KFUser *activeUser, NSError *error))callbackBlock;

///-------------------------------
/// @name Stream Lifecycle
///-------------------------------

/**
 *  Starts a new stream to be fed to KFRecorder
 *
 *  @param endpointCallback Called when request completes for new stream or error
 */
- (void) startNewStream:(void (^)(KFStream *newStream, NSError *error))endpointCallback;
/**
 *  Marks the stream as stopped on the server
 *
 *  @param stream        stream to be stopped
 *  @param callbackBlock (optional) whether or not this was successful
 */
- (void) stopStream:(KFStream*)stream callbackBlock:(void (^)(BOOL success, NSError *error))callbackBlock;
/**
 *  Posts to /api/stream/change the changes in your KFStream
 *
 *  @param stream        stream to be updated
 *  @param callbackBlock (optional) serialized KFStream response or error
 */
- (void) updateMetadataForStream:(KFStream*)stream callbackBlock:(void (^)(KFStream* updatedStream, NSError *error))callbackBlock;

///-------------------------------
/// @name Stream Search
///-------------------------------

/**
 *  Requests all streams created by a particular user
 *
 *  @param username      username to filter by
 *  @param callbackBlock Returns array of KFStreams or error
 */
- (void) requestStreamsForUsername:(NSString*)username callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock;

/**
 *  Returns all the streams created near a certain location
 *
 *  @param location      Center point of search
 *  @param radius        (optional)
 *  @param callbackBlock Array of KFStreams matching query or error
 */
- (void) requestStreamsForLocation:(CLLocation*)location radius:(CLLocationDistance)radius callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock;

/**
 *  Returns all the streams with metadata containing keyword
 *
 *  @param keyword (Optional) If this parameter is omitted it will return all streams
 *  @param callbackBlock Array of KFStreams matching query or error
 */
- (void) requestStreamsByKeyword:(NSString*)keyword callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock;

/**
 *  Returns all the streams associated with this application.
 *
 *  @param callbackBlock Array of KFStreams or error
 */
- (void) requestAllStreams:(void (^)(NSArray *streams, NSError *error))callbackBlock;

@end
