//
//  HLSUploader.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/20/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "HLSUploader.h"
#import "OWSharedS3Client.h"

static NSString * const kBucketName = @"openwatch-livestreamer";

static NSString * const kManifestKey =  @"manifest";
static NSString * const kFileNameKey = @"fileName";

static NSString * const kUploadStateQueued = @"queued";
static NSString * const kUploadStateFinished = @"finished";
static NSString * const kUploadStateUploading = @"uploading";

@interface HLSUploader()
@property (nonatomic) NSUInteger numbersOffset;
@property (nonatomic, strong) NSMutableDictionary *queuedSegments;
@property (nonatomic) NSUInteger nextSegmentIndexToUpload;
@end

@implementation HLSUploader

- (id) initWithDirectoryPath:(NSString *)directoryPath remoteFolderName:(NSString *)remoteFolderName {
    if (self = [super init]) {
        _directoryPath = [directoryPath copy];
        _directoryWatcher = [DirectoryWatcher watchFolderWithPath:_directoryPath delegate:self];
        _files = [NSMutableDictionary dictionary];
        _remoteFolderName = [remoteFolderName copy];
        _scanningQueue = dispatch_queue_create("Scanning Queue", DISPATCH_QUEUE_SERIAL);
        _queuedSegments = [NSMutableDictionary dictionaryWithCapacity:5];
        _numbersOffset = 0;
        _nextSegmentIndexToUpload = 0;
    }
    return self;
}

- (void) uploadNextSegment {
    NSLog(@"nextSegmentIndexToUpload: %d, segmentCount: %d, queuedSegments: %d", _nextSegmentIndexToUpload, self.files.count, self.queuedSegments.count);
    if (_nextSegmentIndexToUpload >= self.files.count - 1) {
        NSLog(@"Cannot upload file currently being recorded at index: %d", _nextSegmentIndexToUpload);
        return;
    }
    NSDictionary *segmentInfo = [_queuedSegments objectForKey:@(_nextSegmentIndexToUpload)];
    NSString *manifest = [segmentInfo objectForKey:kManifestKey];
    NSString *fileName = [segmentInfo objectForKey:kFileNameKey];
    NSString *fileUploadState = [_files objectForKey:fileName];
    if (![fileUploadState isEqualToString:kUploadStateQueued]) {
        NSLog(@"Trying to upload file that isn't queued (%@): %@", fileUploadState, segmentInfo);
        return;
    }
    [_files setObject:kUploadStateUploading forKey:fileName];
    NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];
    NSString *key = [NSString stringWithFormat:@"%@/%@", _remoteFolderName, fileName];
    [[OWSharedS3Client sharedClient] postObjectWithFile:filePath bucket:kBucketName key:key acl:@"public-read" success:^(S3PutObjectResponse *responseObject) {
        dispatch_async(_scanningQueue, ^{
            NSLog(@"Uploaded %@", fileName);
            [_files setObject:kUploadStateFinished forKey:fileName];
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                NSLog(@"Error removing uploaded segment: %@", error.description);
            }
            [_queuedSegments removeObjectForKey:@(_nextSegmentIndexToUpload)];
            [self updateManifestWithString:manifest];
            _nextSegmentIndexToUpload++;
            [self uploadNextSegment];
        });
    } failure:^(NSError *error) {
        dispatch_async(_scanningQueue, ^{
            [_files setObject:kUploadStateQueued forKey:fileName];
            NSLog(@"Failed to upload segment, requeuing %@: %@", fileName, error.description);
            [self uploadNextSegment];
        });
    }];
}

- (void) updateManifestWithString:(NSString*)manifestString {
    NSData *data = [manifestString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *key = [NSString stringWithFormat:@"%@/%@", _remoteFolderName, [_manifestPath lastPathComponent]];
    [[OWSharedS3Client sharedClient] postObjectWithData:data bucket:kBucketName key:key acl:@"public-read" success:^(S3PutObjectResponse *responseObject) {
        NSLog(@"Manifest updated");
    } failure:^(NSError *error) {
        NSLog(@"Error updating manifest: %@", error.description);
    }];
}

- (void) directoryDidChange:(DirectoryWatcher *)folderWatcher {
    dispatch_async(_scanningQueue, ^{
        NSError *error = nil;
        NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:_directoryPath error:&error];
        NSLog(@"Directory changed, fileCount: %lu", (unsigned long)files.count);
        if (error) {
            NSLog(@"Error listing directory contents");
        }
        if (!_manifestPath) {
            [self initializeManifestPathFromFiles:files];
        }
        [self detectNewSegmentsFromFiles:files];
    });
}

- (void) detectNewSegmentsFromFiles:(NSArray*)files {
    if (!_manifestPath) {
        NSLog(@"Manifest path not yet available");
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
                NSLog(@"new file detected: %@", fileName);
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

- (NSURL*) manifestURL {
    NSString *urlString = [NSString stringWithFormat:@"http://%@.s3.amazonaws.com/%@/%@", kBucketName, _remoteFolderName, [_manifestPath lastPathComponent]];
    return [NSURL URLWithString:urlString];
}

@end
