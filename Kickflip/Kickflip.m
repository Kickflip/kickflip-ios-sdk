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
@property (nonatomic) NSString *h264Profile;
@property (nonatomic) NSUInteger resolutionWidth;
@property (nonatomic) NSUInteger resolutionHeight;
@property (nonatomic) NSUInteger minBitrate;
@property (nonatomic) NSUInteger maxBitrate;
@property (nonatomic) NSUInteger initialBitrate;
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
        _h264Profile = AVVideoProfileLevelH264BaselineAutoLevel;
        _resolutionWidth = 568;
        _resolutionHeight = 320;
        _minBitrate = 456 * 1000; // 400 Kbps
        _maxBitrate = 2056 * 1000; // 2 Mbps
        _initialBitrate = _maxBitrate;
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

+ (void)setH264Profile:(NSString *)profile {
    [Kickflip sharedInstance].h264Profile = profile;
}

+ (NSString *)h264Profile {
    return [Kickflip sharedInstance].h264Profile;
}

+ (void)setResolutionWidth:(int)width height:(int)height {
    [Kickflip sharedInstance].resolutionWidth = width;
    [Kickflip sharedInstance].resolutionHeight = height;
}

+ (double)resolutionWidth {
    return [Kickflip sharedInstance].resolutionWidth;
}

+ (double)resolutionHeight {
    return [Kickflip sharedInstance].resolutionHeight;
}

+ (void) setMinBitrate:(double)minBitrate {
    [Kickflip sharedInstance].minBitrate = minBitrate;
}

+ (double) minBitrate {
    return [Kickflip sharedInstance].minBitrate;
}

+ (void) setMaxBitrate:(double)maxBitrate {
    [Kickflip sharedInstance].maxBitrate = maxBitrate;
}

+ (double) maxBitrate {
    return [Kickflip sharedInstance].maxBitrate;
}

+ (void) setInitialBitrate:(double)initialBitrate {
    if (initialBitrate < [self minBitrate]) {
        initialBitrate = [self minBitrate];
    }
    
    if (initialBitrate > [self maxBitrate]) {
        initialBitrate = [self maxBitrate];
    }
    
    [Kickflip sharedInstance].initialBitrate = initialBitrate;
}

+ (double) initialBitrate {
    return [Kickflip sharedInstance].initialBitrate;
}

+ (BOOL) useAdaptiveBitrate {
    return [Kickflip sharedInstance].useAdaptiveBitrate;
}

+ (void) setUseAdaptiveBitrate:(BOOL)enabled {
    [Kickflip sharedInstance].useAdaptiveBitrate = enabled;
}

@end
