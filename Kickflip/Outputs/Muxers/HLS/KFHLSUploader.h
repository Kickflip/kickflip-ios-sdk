//
//  KFHLSUploader.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/20/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFDirectoryWatcher.h"

@class KFS3Stream, KFHLSUploader;

@protocol KFHLSUploaderDelegate <NSObject>
- (void) uploader:(KFHLSUploader*)uploader didUploadSegmentAtURL:(NSURL*)segmentURL uploadSpeed:(double)uploadSpeed; //KBps
- (void) uploader:(KFHLSUploader *)uploader manifestReadyAtURL:(NSURL*)manifestURL;
@end

@interface KFHLSUploader : NSObject <KFDirectoryWatcherDelegate>

@property (nonatomic, weak) id<KFHLSUploaderDelegate> delegate;
@property (readonly, nonatomic, strong) NSString *directoryPath;
@property (nonatomic) dispatch_queue_t scanningQueue;
@property (nonatomic) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) KFS3Stream *stream;
@property (nonatomic) BOOL useSSL;

- (id) initWithDirectoryPath:(NSString*)directoryPath stream:(KFS3Stream*)stream;

- (NSURL*) manifestURL;

@end
