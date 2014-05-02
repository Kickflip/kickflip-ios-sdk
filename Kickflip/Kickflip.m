//
//  Kickflip.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "Kickflip.h"
#import "KFLog.h"
#import "KFBroadcastViewController.h"

@interface Kickflip()
@property (nonatomic, copy) NSString *apiKey;
@property (nonatomic, copy) NSString *apiSecret;
@property (nonatomic) NSUInteger maxBitrate;
@property (nonatomic) BOOL useAdaptiveBitrate;
@end

static Kickflip *_kickflip = nil;

@implementation Kickflip

+ (void) presentBroadcasterFromViewController:(UIViewController *)viewController ready:(KFBroadcastReadyBlock)readyBlock completion:(KFBroadcastCompletionBlock)completionBlock {
    KFBroadcastViewController *broadcastViewController = [[KFBroadcastViewController alloc] init];
    broadcastViewController.readyBlock = readyBlock;
    broadcastViewController.completionBlock = completionBlock;
    [viewController presentViewController:broadcastViewController animated:YES completion:nil];
}

+ (Kickflip*) sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _kickflip = [[Kickflip alloc] init];
    });
    return _kickflip;
}

- (id) init {
    if (self = [super init]) {
        _maxBitrate = 2000 * 1000; // 2 Mbps
        _useAdaptiveBitrate = YES;
    }
    return self;
}


+ (void) setupWithAPIKey:(NSString *)key secret:(NSString *)secret {
    Kickflip *kickflip = [Kickflip sharedInstance];
    kickflip.apiKey = key;
    kickflip.apiSecret = secret;
    KFUser *activeUser = [KFUser activeUser];
    if (!activeUser) {
        [[KFAPIClient sharedClient] requestNewActiveUserWithUsername:nil callbackBlock:^(KFUser *newUser, NSError *error) {
            if (error) {
                DDLogError(@"Error pre-fetching new user: %@", error);
            } else {
                DDLogVerbose(@"New user fetched pre-emptively: %@", newUser);
            }
        }];
    }
}

+ (NSString*) apiKey {
    return [Kickflip sharedInstance].apiKey;
}

+ (NSString*) apiSecret {
    return [Kickflip sharedInstance].apiSecret;
}

+ (void) setMaxBitrate:(double)maxBitrate {
    [Kickflip sharedInstance].maxBitrate = maxBitrate;
}

+ (double) maxBitrate {
    return [Kickflip sharedInstance].maxBitrate;
}

+ (BOOL) useAdaptiveBitrate {
    return [Kickflip sharedInstance].useAdaptiveBitrate;
}

+ (void) setUseAdaptiveBitrate:(BOOL)enabled {
    [Kickflip sharedInstance].useAdaptiveBitrate = enabled;
}

@end
