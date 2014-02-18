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
@end

@implementation KFHLSUploader

- (id) initWithDirectoryPath:(NSString *)directoryPath stream:(KFS3Stream *)stream {
    if (self = [super init]) {
        self.stream = stream;
        _directoryPath = [directoryPath copy];
        _directoryWatcher = [KFDirectoryWatcher watchFolderWithPath:_directoryPath delegate:self];
        _files = [NSMutableDictionary dictionary];
        _scanningQueue = dispatch_queue_create("Scanning Queue", DISPATCH_QUEUE_SERIAL);
        _queuedSegments = [NSMutableDictionary dictionaryWithCapacity:5];
        _numbersOffset = 0;
        _nextSegmentIndexToUpload = 0;
        self.s3Client = [[OWS3Client alloc] initWithAccessKey:self.stream.awsAccessKey secretKey:self.stream.awsSecretKey];
        //self.s3Client.region = US_WEST_1;
        self.s3Client.useSSL = NO;
        self.s3Client.s3.timeout = 10;
    }
    return self;
}

- (void) uploadNextSegment {
    DDLogVerbose(@"nextSegmentIndexToUpload: %d, segmentCount: %d, queuedSegments: %d", _nextSegmentIndexToUpload, self.files.count, self.queuedSegments.count);
    if (_nextSegmentIndexToUpload >= self.files.count - 1) {
        DDLogWarn(@"Cannot upload file currently being recorded at index: %d", _nextSegmentIndexToUpload);
        return;
    }
    NSDictionary *segmentInfo = [_queuedSegments objectForKey:@(_nextSegmentIndexToUpload)];
    NSString *manifest = [segmentInfo objectForKey:kManifestKey];
    NSString *fileName = [segmentInfo objectForKey:kFileNameKey];
    NSString *fileUploadState = [_files objectForKey:fileName];
    if (![fileUploadState isEqualToString:kUploadStateQueued]) {
        DDLogWarn(@"Trying to upload file that isn't queued (%@): %@", fileUploadState, segmentInfo);
        return;
    }
    [_files setObject:kUploadStateUploading forKey:fileName];
    NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];
    NSString *key = [self awsKeyForStream:self.stream fileName:fileName];
    
    [self.s3Client postObjectWithFile:filePath bucket:self.stream.bucketName key:key acl:@"public-read" success:^(S3PutObjectResponse *responseObject) {
        dispatch_async(_scanningQueue, ^{
            DDLogVerbose(@"Uploaded %@", fileName);
            [_files setObject:kUploadStateFinished forKey:fileName];
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                DDLogError(@"Error removing uploaded segment: %@", error.description);
            }
            [_queuedSegments removeObjectForKey:@(_nextSegmentIndexToUpload)];
            [self updateManifestWithString:manifest];
            _nextSegmentIndexToUpload++;
            [self uploadNextSegment];
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
    return [NSString stringWithFormat:@"%@/%@/%@", stream.user.username, stream.streamID, fileName];
}

- (void) updateManifestWithString:(NSString*)manifestString {
    NSData *data = [manifestString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *key = [self awsKeyForStream:self.stream fileName:[_manifestPath lastPathComponent]];
    [self.s3Client postObjectWithData:data bucket:self.stream.bucketName key:key acl:@"public-read" success:^(S3PutObjectResponse *responseObject) {
        DDLogInfo(@"Manifest updated");
    } failure:^(NSError *error) {
        DDLogError(@"Error updating manifest: %@", error.description);
    }];
}

- (void) directoryDidChange:(KFDirectoryWatcher *)folderWatcher {
    dispatch_async(_scanningQueue, ^{
        NSError *error = nil;
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_directoryPath error:&error];
        DDLogInfo(@"Directory changed, fileCount: %lu", (unsigned long)files.count);
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
        DDLogWarn(@"Manifest path not yet available");
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
                DDLogInfo(@"new file detected: %@", fileName);
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

- (NSURL*) manifestURLWithSSL:(BOOL)withSSL {
    NSString *key = [self awsKeyForStream:self.stream fileName:[_manifestPath lastPathComponent]];
    NSString *ssl = @"";
    if (withSSL) {
        ssl = @"s";
    }
    NSString *urlString = [NSString stringWithFormat:@"http%@://%@.s3.amazonaws.com/%@", ssl, self.stream.bucketName, key];
    return [NSURL URLWithString:urlString];
}

@end
