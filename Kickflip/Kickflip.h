//
//  Kickflip.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef void (^KFBroadcastReadyBlock)(NSURL *streamURL);
typedef void (^KFBroadcastCompletionBlock)(BOOL success, NSError* error);

@interface Kickflip : NSObject

+ (void) setupWithAPIKey:(NSString*)key secret:(NSString*)secret;
+ (void) presentBroadcasterFromViewController:(UIViewController*)viewController ready:(KFBroadcastReadyBlock)readyBlock completion:(KFBroadcastCompletionBlock)completionBlock;

+ (double) maxBitrate; // defaults to 2 Mbps
+ (void) setMaxBitrate:(double)maxBitrate; // bits per second
+ (BOOL) useAdaptiveBitrate; // default YES, will reduce bitrate to maintain live stream
+ (void) setUseAdaptiveBitrate:(BOOL)enabled;

+ (NSString*) apiKey;
+ (NSString*) apiSecret;

@end
