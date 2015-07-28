//
//  KFHLSMonitor.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFHLSMonitor.h"
#import "KFHLSUploader.h"
#import "KFLog.h"

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
        self.monitorQueue = dispatch_queue_create("KFHLSMonitor Queue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void) startMonitoringFolderPath:(NSString *)path endpoint:(KFS3Stream *)endpoint delegate:(id<KFHLSUploaderDelegate>)delegate {
    self.delegate = delegate;
    
    dispatch_async(self.monitorQueue, ^{
        KFHLSUploader *hlsUploader = [[KFHLSUploader alloc] initWithDirectoryPath:path stream:endpoint];
        hlsUploader.delegate = self;
        [self.hlsUploaders setObject:hlsUploader forKey:path];
    });
}

- (void) finishUploadingContentsAtFolderPath:(NSString*)path endpoint:(KFS3Stream*)endpoint {
    dispatch_async(self.monitorQueue, ^{
        KFHLSUploader *hlsUploader = [self.hlsUploaders objectForKey:path];
        if (!hlsUploader) {
            hlsUploader = [[KFHLSUploader alloc] initWithDirectoryPath:path stream:endpoint];
            [self.hlsUploaders setObject:hlsUploader forKey:path];
        }
        [hlsUploader finishedRecording];
    });
}

#pragma mark - KFHLSUploaderDelegate

- (void) uploader:(KFHLSUploader*)uploader didUploadPartOfASegmentAtUploadSpeed:(double)uploadSpeed {
    [self.delegate uploader:uploader didUploadPartOfASegmentAtUploadSpeed:uploadSpeed];
}

- (void) uploader:(KFHLSUploader *)uploader didUploadSegmentAtURL:(NSURL *)segmentURL uploadSpeed:(double)uploadSpeed numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments {
    [self.delegate uploader:uploader didUploadSegmentAtURL:segmentURL uploadSpeed:uploadSpeed numberOfQueuedSegments:numberOfQueuedSegments];
}

- (void) uploader:(KFHLSUploader *)uploader liveManifestReadyAtURL:(NSURL*)manifestURL {
    [self.delegate uploader:uploader liveManifestReadyAtURL:manifestURL];
}

- (void) uploader:(KFHLSUploader *)uploader thumbnailReadyAtURL:(NSURL*)manifestURL {
    [self.delegate uploader:uploader thumbnailReadyAtURL:manifestURL];
}

- (void) uploaderHasFinished:(KFHLSUploader*)uploader {
    dispatch_async(self.monitorQueue, ^{
        [self.hlsUploaders removeObjectForKey:uploader.directoryPath];
    });
    
    [self.delegate uploaderHasFinished:uploader];
}

@end
