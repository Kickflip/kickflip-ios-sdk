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

/**
 *  Native object for serialized /api/stream responses
 */
@interface KFStream : MTLModel <MTLJSONSerializing>

/**
 *  Stream owner, maps to a KFUser
 *  @see KFUser
 */
@property (nonatomic, strong) NSString *username;

/**
 *  Stream UUID (unique identifier)
 */
@property (nonatomic, strong, readonly) NSString *streamID;

/**
 *  HLS or RTMP (currently only HLS is supported)
 */
@property (nonatomic, strong, readonly) NSString *streamType;

/**
 *  Currently unused (for RTMP support)
 */
@property (nonatomic, strong, readonly) NSURL *uploadURL;

/**
 *  Location of raw .m3u8 HLS manifest for use in native media players
 */
@property (nonatomic, strong, readonly) NSURL *streamURL;

/**
 *  kickflip.io URL for public consumption on the web
 */
@property (nonatomic, strong, readonly) NSURL *kickflipURL;

/**
 *  When recording was started
 */
@property (nonatomic, strong, readonly) NSDate *startDate;

/**
 *  When recording was finished
 */
@property (nonatomic, strong, readonly) NSDate *finishDate;

/**
 *  URL for thumbnail jpg, generated client-side for local recordings
 */
@property (nonatomic, strong) NSURL *thumbnailURL;

/**
 *  City metadata returned by local reverse geocoder
 */
@property (nonatomic, strong) NSString *city;
/**
 *  Country
 */
@property (nonatomic, strong) NSString *country;
/**
 *  State
 */
@property (nonatomic, strong) NSString *state;

/**
 *  Start location of recording
 */
@property (nonatomic, strong) CLLocation *startLocation;

/**
 *  End location of recording
 */
@property (nonatomic, strong) CLLocation *endLocation;

/**
 *  State of the stream
 *  @see KFStreamState
 */
@property (nonatomic) KFStreamState streamState;

/**
 *  Whether or not a recording is currently being broadcast.
 *  Currently this is calculated by the startDate and finishDate info.
 *
 *  @return It's live!
 */
- (BOOL) isLive;

@end
