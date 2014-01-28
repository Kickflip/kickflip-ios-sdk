//
//  KFBroadcaster.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFRecorder.h"
#import "KFUploader.h"

@class KFBroadcaster;

@protocol KFBroadcasterDelegate <NSObject>
- (void) broadcasterDidStartBroadcasting:(KFBroadcaster*)recorder;
- (void) broadcasterDidFinishBroadcasting:(KFBroadcaster*)recorder;
- (void) broadcaster:(KFBroadcaster*)broadcaster videoReadyAtURL:(NSURL*)url;
@end

@interface KFBroadcaster : NSObject

@property (nonatomic, strong) KFRecorder *recorder;
@property (nonatomic, strong) KFUploader *uploader;
@property (nonatomic, weak) id<KFBroadcasterDelegate> delegate;

- (void) startBroadcaster;
- (void) stopBroadcaster;


@end
