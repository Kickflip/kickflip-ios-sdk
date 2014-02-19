//
//  KFStream.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@interface KFStream : NSObject

@property (nonatomic, strong) KFUser *user;
@property (nonatomic, strong) NSString *streamType;
@property (nonatomic, strong) NSString *streamID;
@property (nonatomic, strong) NSURL *uploadURL;
@property (nonatomic, strong) NSURL *streamURL;
@property (nonatomic, strong) NSURL *kickflipURL;
@property (nonatomic, strong) NSURL *chatURL;
@property (nonatomic) KFStreamState streamState;

- (instancetype) initWithUser:(KFUser*)user parameters:(NSDictionary*)parameters;

- (NSDictionary*) dictionaryRepresentation;

@end
