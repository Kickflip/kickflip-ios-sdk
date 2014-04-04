//
//  KFStream.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
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

extern const struct KFStreamAttributes {
    __unsafe_unretained NSString *streamType;
	__unsafe_unretained NSString *streamID;
	__unsafe_unretained NSString *uploadURL;
    __unsafe_unretained NSString *streamURL;
    __unsafe_unretained NSString *kickflipURL;
	__unsafe_unretained NSString *chatURL;
    __unsafe_unretained NSString *username;
    __unsafe_unretained NSString *startDate;
    __unsafe_unretained NSString *finishDate;
} KFStreamAttributes;

@interface KFStream : MTLModel <MTLJSONSerializing>

@property (nonatomic, strong, readonly) NSString *streamType;
@property (nonatomic, strong) NSString *streamID;
@property (nonatomic, strong, readonly) NSURL *uploadURL;
@property (nonatomic, strong, readonly) NSURL *streamURL;
@property (nonatomic, strong, readonly) NSURL *kickflipURL;
@property (nonatomic) KFStreamState streamState;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong, readonly) NSDate *startDate;
@property (nonatomic, strong, readonly) NSDate *finishDate;


@end
