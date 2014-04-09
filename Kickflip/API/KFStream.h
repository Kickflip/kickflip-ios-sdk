//
//  KFStream.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "Mantle.h"

@class KFUser;

typedef NS_ENUM(NSUInteger, KFStreamState) {
    KFStreamStateUndefined = 0,
    KFStreamStateStreaming = 1,
    KFStreamStatePaused = 2,
    KFStreamStateStopped = 3,
    KFStreamStateFinished = 4,
    KFStreamStateFailed = 5
};

extern NSString * const KFStreamTypeKey;

@interface KFStream : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong) NSString *username;

@property (nonatomic, strong, readonly) NSString *streamID;
@property (nonatomic, strong, readonly) NSString *streamType;
@property (nonatomic, strong, readonly) NSURL *uploadURL;
@property (nonatomic, strong, readonly) NSURL *streamURL;
@property (nonatomic, strong, readonly) NSURL *kickflipURL;
@property (nonatomic, strong, readonly) NSDate *startDate;
@property (nonatomic, strong, readonly) NSDate *finishDate;

@property (nonatomic, strong) NSURL *thumbnailURL;

// Location information
@property (nonatomic, strong) NSString *city;
@property (nonatomic, strong) NSString *country;
@property (nonatomic, strong) NSString *state;

@property (nonatomic, strong) CLLocation *startLocation;
@property (nonatomic, strong) CLLocation *endLocation;

@property (nonatomic) KFStreamState streamState;

- (BOOL) isLive;

@end
