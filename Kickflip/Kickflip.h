//
//  Kickflip.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFRecordingViewController.h"
#import "KFBroadcaster.h"

@interface Kickflip : NSObject

+ (void) setupWithAPIKey:(NSString*)key secret:(NSString*)secret;
+ (void) presentBroadcastViewFromViewController:(UIViewController*)viewController ready:(void (^)(NSURL *streamURL, NSError *error))readyBlock completion:(void (^)(void))completionBlock;

+ (KFBroadcaster*) broadcaster;
+ (NSString*) apiKey;
+ (NSString*) apiSecret;

@end
