//
//  KFHLSMonitor.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFHLSMonitor.h"
#import "KFHLSUploader.h"

@interface KFHLSMonitor()
@property (nonatomic, strong) NSMutableDictionary *hlsUploaders;
@property (nonatomic) dispatch_queue_t monitorQueue;
@end

static KFHLSMonitor *_sharedMonitor = nil;

@implementation KFHLSMonitor

+ (KFHLSMonitor*) sharedMonitor {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedMonitor = [[KFHLSMonitor alloc] init];
    });
    return _sharedMonitor;
}

- (id) init {
    if (self = [super init]) {
        self.hlsUploaders = [NSMutableDictionary dictionary];
        self.monitorQueue = dispatch_queue_create("KFHLSMonitor Queue", 0);
    }
    return self;
}

- (void) startMonitoringFolderPath:(NSString *)path endpoint:(KFS3Stream *)endpoint delegate:(id<KFHLSUploaderDelegate>)delegate {
    KFHLSUploader *hlsUploader = [[KFHLSUploader alloc] initWithDirectoryPath:path stream:endpoint];
    hlsUploader.delegate = delegate;
    [self.hlsUploaders setObject:hlsUploader forKey:path];
}

- (void) finishUploadingContentsAtFolderPath:(NSString*)path endpoint:(KFS3Stream*)endpoint {
    KFHLSUploader *hlsUploader = [self.hlsUploaders objectForKey:path];
    if (!hlsUploader) {
         hlsUploader = [[KFHLSUploader alloc] initWithDirectoryPath:path stream:endpoint];
        [self.hlsUploaders setObject:hlsUploader forKey:path];
    }
    hlsUploader.delegate = self;
}

- (void) uploader:(KFHLSUploader *)uploader didUploadSegmentAtURL:(NSURL *)segmentURL uploadSpeed:(double)uploadSpeed numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments {
    // TODO: determine if finished and remove reference to uploader
    DDLogInfo(@"[Background monitor] Uploaded segment %@ @ %f KB/s, numberOfQueuedSegments %d", segmentURL, uploadSpeed, numberOfQueuedSegments);
}

- (void) uploader:(KFHLSUploader *)uploader manifestReadyAtURL:(NSURL *)manifestURL {
    
}

@end
