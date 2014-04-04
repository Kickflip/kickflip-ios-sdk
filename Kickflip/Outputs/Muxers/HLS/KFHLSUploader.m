//
//  KFHLSUploader.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/20/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "KFHLSUploader.h"
#import "KFS3Stream.h"
#import "OWS3Client.h"
#import "KFUser.h"
#import "KFLog.h"

static NSString * const kManifestKey =  @"manifest";
static NSString * const kFileNameKey = @"fileName";

static NSString * const kUploadStateQueued = @"queued";
static NSString * const kUploadStateFinished = @"finished";
static NSString * const kUploadStateUploading = @"uploading";

@interface KFHLSUploader()
@property (nonatomic) NSUInteger numbersOffset;
@property (nonatomic, strong) NSMutableDictionary *queuedSegments;
@property (nonatomic) NSUInteger nextSegmentIndexToUpload;
@property (nonatomic, strong) OWS3Client *s3Client;
@property (nonatomic, strong) KFDirectoryWatcher *directoryWatcher;
@property (nonatomic, strong) NSMutableDictionary *files;
@property (nonatomic, strong) NSString *manifestPath;
@property (nonatomic) BOOL manifestReady;
@property (nonatomic, strong) NSString *finalManifestString;
@property (nonatomic) BOOL isFinishedRecording;
@property (nonatomic) BOOL hasUploadedFinalManifest;
@end

@implementation KFHLSUploader

- (id) initWithDirectoryPath:(NSString *)directoryPath stream:(KFS3Stream *)stream {
    if (self = [super init]) {
        self.stream = stream;
        _directoryPath = [directoryPath copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            self.directoryWatcher = [KFDirectoryWatcher watchFolderWithPath:_directoryPath delegate:self];
        });
        _files = [NSMutableDictionary dictionary];
        _scanningQueue = dispatch_queue_create("KFHLSUploader Scanning Queue", DISPATCH_QUEUE_SERIAL);
        _callbackQueue = dispatch_queue_create("KFHLSUploader Callback Queue", DISPATCH_QUEUE_SERIAL);
        _queuedSegments = [NSMutableDictionary dictionaryWithCapacity:5];
        _numbersOffset = 0;
        _nextSegmentIndexToUpload = 0;
        _manifestReady = NO;
        _isFinishedRecording = NO;
        self.s3Client = [[OWS3Client alloc] initWithAccessKey:self.stream.awsAccessKey secretKey:self.stream.awsSecretKey];
        self.s3Client.useSSL = NO;
        self.manifestGenerator = [[KFHLSManifestGenerator alloc] initWithTargetDuration:10 playlistType:KFHLSManifestPlaylistTypeVOD];
    }
    return self;
}

#warning This code is buggy and doesnt finish uploading all segments or the VOD properly
- (void) finishedRecording {
    self.isFinishedRecording = YES;
    if (!self.hasUploadedFinalManifest) {
        [self updateManifestWithString:nil];
    }
}

- (void) setUseSSL:(BOOL)useSSL {
    _useSSL = useSSL;
    self.s3Client.useSSL = useSSL;
}

- (void) uploadNextSegment {
    DDLogVerbose(@"nextSegmentIndexToUpload: %d, segmentCount: %d, queuedSegments: %d", _nextSegmentIndexToUpload, self.files.count, self.queuedSegments.count);
    if (_nextSegmentIndexToUpload >= self.files.count - 1) {
        DDLogVerbose(@"Cannot upload file currently being recorded at index: %d", _nextSegmentIndexToUpload);
        return;
    }
    NSDictionary *segmentInfo = [_queuedSegments objectForKey:@(_nextSegmentIndexToUpload)];
    NSString *manifest = [segmentInfo objectForKey:kManifestKey];
    NSString *fileName = [segmentInfo objectForKey:kFileNameKey];
    NSString *fileUploadState = [_files objectForKey:fileName];
    if (![fileUploadState isEqualToString:kUploadStateQueued]) {
        DDLogVerbose(@"Trying to upload file that isn't queued (%@): %@", fileUploadState, segmentInfo);
        return;
    }
    [_files setObject:kUploadStateUploading forKey:fileName];
    NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];
    NSString *key = [self awsKeyForStream:self.stream fileName:fileName];
    
    NSDate *uploadStartDate = [NSDate date];
    NSError *error = nil;
    NSDictionary *fileStats = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
    if (error) {
        DDLogError(@"Error getting stats of path %@: %@", filePath, error);
    }
    uint64_t fileSize = [fileStats fileSize];
    
    [self.s3Client postObjectWithFile:filePath bucket:self.stream.bucketName key:key acl:@"public-read" success:^(S3PutObjectResponse *responseObject) {
        dispatch_async(_scanningQueue, ^{
            NSDate *uploadFinishDate = [NSDate date];
            NSTimeInterval timeToUpload = [uploadFinishDate timeIntervalSinceDate:uploadStartDate];
            double bytesPerSecond = fileSize / timeToUpload;
            double KBps = bytesPerSecond / 1024;
            [_files setObject:kUploadStateFinished forKey:fileName];
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                DDLogError(@"Error removing uploaded segment: %@", error.description);
            }
            [_queuedSegments removeObjectForKey:@(_nextSegmentIndexToUpload)];
            NSUInteger queuedSegmentsCount = _queuedSegments.count;
            [self.manifestGenerator appendFromLiveManifest:manifest];
            [self updateManifestWithString:manifest];
            _nextSegmentIndexToUpload++;
            [self uploadNextSegment];
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:didUploadSegmentAtURL:uploadSpeed:numberOfQueuedSegments:)]) {
                NSURL *url = [self urlWithFileName:fileName];
                dispatch_async(self.callbackQueue, ^{
                    [self.delegate uploader:self didUploadSegmentAtURL:url uploadSpeed:KBps numberOfQueuedSegments:queuedSegmentsCount];
                });
            }
        });
    } failure:^(NSError *error) {
        dispatch_async(_scanningQueue, ^{
            [_files setObject:kUploadStateQueued forKey:fileName];
            DDLogError(@"Failed to upload segment, requeuing %@: %@", fileName, error.description);
            [self uploadNextSegment];
        });
    }];
}

- (NSString*) awsKeyForStream:(KFStream*)stream fileName:(NSString*)fileName {
    return [NSString stringWithFormat:@"%@/%@/%@", stream.username, stream.streamID, fileName];
}

- (void) updateManifestWithString:(NSString*)manifestString {
    if (self.isFinishedRecording) {
        [self.manifestGenerator finalizeManifest];
        manifestString = [self.manifestGenerator manifestString];
    }
    NSData *data = [manifestString dataUsingEncoding:NSUTF8StringEncoding];
    DDLogVerbose(@"New manifest:\n%@", manifestString);
    NSString *key = [self awsKeyForStream:self.stream fileName:[_manifestPath lastPathComponent]];
    [self.s3Client postObjectWithData:data bucket:self.stream.bucketName key:key acl:@"public-read" success:^(S3PutObjectResponse *responseObject) {
        dispatch_async(self.callbackQueue, ^{
            if (!_manifestReady) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:manifestReadyAtURL:)]) {
                    [self.delegate uploader:self manifestReadyAtURL:[self manifestURL]];
                }
                _manifestReady = YES;
            }
            if (self.isFinishedRecording) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(uploaderHasFinished:)]) {
                    [self.delegate uploaderHasFinished:self];
                }
            }
        });
    } failure:^(NSError *error) {
        DDLogError(@"Error updating manifest: %@", error.description);
    }];
}

- (void) directoryDidChange:(KFDirectoryWatcher *)folderWatcher {
    dispatch_async(_scanningQueue, ^{
        NSError *error = nil;
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_directoryPath error:&error];
        DDLogVerbose(@"Directory changed, fileCount: %lu", (unsigned long)files.count);
        if (error) {
            DDLogError(@"Error listing directory contents");
        }
        if (!_manifestPath) {
            [self initializeManifestPathFromFiles:files];
        }
        [self detectNewSegmentsFromFiles:files];
    });
}

- (void) detectNewSegmentsFromFiles:(NSArray*)files {
    if (!_manifestPath) {
        DDLogVerbose(@"Manifest path not yet available");
        return;
    }
    [files enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
        NSArray *components = [fileName componentsSeparatedByString:@"."];
        NSString *filePrefix = [components firstObject];
        NSString *fileExtension = [components lastObject];
        if ([fileExtension isEqualToString:@"ts"]) {
            NSString *uploadState = [_files objectForKey:fileName];
            if (!uploadState) {
                NSString *manifestSnapshot = [self manifestSnapshot];
                NSUInteger segmentIndex = [self indexForFilePrefix:filePrefix];
                NSDictionary *segmentInfo = @{kManifestKey: manifestSnapshot,
                                                kFileNameKey: fileName};
                DDLogVerbose(@"new file detected: %@", fileName);
                [_files setObject:kUploadStateQueued forKey:fileName];
                [_queuedSegments setObject:segmentInfo forKey:@(segmentIndex)];
                [self uploadNextSegment];
            }
        }
    }];
}

- (void) initializeManifestPathFromFiles:(NSArray*)files {
    [files enumerateObjectsUsingBlock:^(NSString *fileName, NSUInteger idx, BOOL *stop) {
        if ([[fileName pathExtension] isEqualToString:@"m3u8"]) {
            NSArray *components = [fileName componentsSeparatedByString:@"."];
            NSString *filePrefix = [components firstObject];
            _manifestPath = [_directoryPath stringByAppendingPathComponent:fileName];
            _numbersOffset = filePrefix.length;
            NSAssert(_numbersOffset > 0, nil);
            *stop = YES;
        }
    }];
}

- (NSString*) manifestSnapshot {
    return [NSString stringWithContentsOfFile:_manifestPath encoding:NSUTF8StringEncoding error:nil];
}

- (NSUInteger) indexForFilePrefix:(NSString*)filePrefix {
    NSString *numbers = [filePrefix substringFromIndex:_numbersOffset];
    return [numbers integerValue];
}

- (NSURL*) urlWithFileName:(NSString*)fileName {
    NSString *key = [self awsKeyForStream:self.stream fileName:fileName];
    NSString *ssl = @"";
    if (self.useSSL) {
        ssl = @"s";
    }
    NSString *urlString = [NSString stringWithFormat:@"http%@://%@.s3.amazonaws.com/%@", ssl, self.stream.bucketName, key];
    return [NSURL URLWithString:urlString];
}

- (NSURL*) manifestURL {
    return [self urlWithFileName:[_manifestPath lastPathComponent]];
}

@end
