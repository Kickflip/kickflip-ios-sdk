//
//  Kickflip.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "KFAPIClient.h"
#import "KFUser.h"
#import "KFStream.h"

/**
 *  Block executed when stream is ready.
 *
 *  @param streamURL URL to the streamable m3u8
 *  @see presentBroadcasterFromViewController:ready:completion:
 */
typedef void (^KFBroadcastReadyBlock)(KFStream *stream);

/**
 *  Block executed when completed live broadcast
 *
 *  @param success Whether or not broadcast was successful
 *  @param error   Any error that occurred
 *  @see presentBroadcasterFromViewController:ready:completion:
 */
typedef void (^KFBroadcastCompletionBlock)(BOOL success, NSError* error);

/**
 *  Kickflip is the easiest way to broadcast live video. Sign up today at https://kickflip.io
 */
@interface Kickflip : NSObject

///-------------------------------
/// @name Setup
///-------------------------------

/**
 *  Initilize the Kickflip client.
 *
 *  @param key    API key from kickflip.io
 *  @param secret API secret from kickflip.io
 */
+ (void) setupWithAPIKey:(NSString*)key secret:(NSString*)secret;

/**
 *  Returns the active API key.
 *
 *  @return API key from kickflip.io
 *  @see setupWithAPIKey:secret:
 */
+ (NSString*) apiKey;
/**
 *  Returns the active API secret
 *
 *  @return API secret from kickflip.io
 *  @see setupWithAPIKey:secret:
 */
+ (NSString*) apiSecret;

///-------------------------------
/// @name Broadcast
///-------------------------------

/**
 *  Presents KFBroadcastViewController from your view controller.
 *
 *  @param viewController  Presenting controller
 *  @param readyBlock      Called when streamURL is ready
 *  @param completionBlock Called when broadcaster is dismissed
 */
+ (void) presentBroadcasterFromViewController:(UIViewController*)viewController ready:(KFBroadcastReadyBlock)readyBlock completion:(KFBroadcastCompletionBlock)completionBlock;

///-------------------------------
/// @name Configuration
///-------------------------------

/**
 *  Maximum bitrate (combined video + audio)
 *
 *  @return Defaults to 2 Mbps
 */
+ (double) maxBitrate;

/**
 *  Sets max bitrate (in bits per second).
 *
 *  @param maxBitrate Maximum bitrate for combined video+audio
 *  @warn Do not set this value to lower than ~300 Kbps
 */
+ (void) setMaxBitrate:(double)maxBitrate;

/**
 *  Whether or not to actively adjust the bitrate to network conditions.
 *
 *  @return Defaults to YES
 */
+ (BOOL) useAdaptiveBitrate;

/**
 *  Whether or not to actively adjust the bitrate to network conditions.
 *
 *  @param enabled BOOL
 */
+ (void) setUseAdaptiveBitrate:(BOOL)enabled;


@end
