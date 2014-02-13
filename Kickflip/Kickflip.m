//
//  Kickflip.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "Kickflip.h"
#import "KFBroadcastViewController.h"
#import "KFAPIClient.h"
#import "KFUser.h"
#import "KFLog.h"

static NSString *_apiKey;
static NSString *_apiSecret;

@implementation Kickflip

+ (void) presentBroadcasterFromViewController:(UIViewController *)viewController ready:(void (^)(NSURL *, NSError *))readyBlock completion:(void (^)(void))completionBlock {
    KFBroadcastViewController *broadcastViewController = [[KFBroadcastViewController alloc] init];
    [viewController presentViewController:broadcastViewController animated:YES completion:completionBlock];
}

+ (void) initialize {
    _apiKey = nil;
    _apiSecret = nil;
}

+ (void) setupWithAPIKey:(NSString *)key secret:(NSString *)secret {
    _apiKey = [key copy];
    _apiSecret = [secret copy];
    KFUser *activeUser = [KFUser activeUser];
    if (!activeUser) {
        [[KFAPIClient sharedClient] requestNewUser:^(KFUser *newUser, NSError *error) {
            if (error) {
                DDLogError(@"Error pre-fetching new user: %@", error);
            } else {
                DDLogVerbose(@"New user: %@", newUser);
            }
        }];
    }
}

+ (NSString*) apiKey {
    return _apiKey;
}

+ (NSString*) apiSecret {
    return _apiSecret;
}

@end
