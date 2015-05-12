//
//  KFHLSUploader.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/20/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "KFHLSUploader.h"
#import "KFS3Stream.h"
#import "KFUser.h"
#import "KFLog.h"
#import "KFAPIClient.h"
#import "KFAWSCredentialsProvider.h"
#import <AWSS3/AWSS3.h>

static NSString * const kManifestKey =  @"manifest";
static NSString * const kFileNameKey = @"fileName";
static NSString * const kFileStartDateKey = @"startDate";

static NSString * const kVODManifestFileName = @"vod.m3u8";


static NSString * const kUploadStateQueued = @"queued";
static NSString * const kUploadStateFinished = @"finished";
static NSString * const kUploadStateUploading = @"uploading";
static NSString * const kUploadStateFailed = @"failed";

static NSString * const kKFS3TransferManagerKey = @"kKFS3TransferManagerKey";
static NSString * const kKFS3Key = @"kKFS3Key";


@interface KFHLSUploader()
@property (nonatomic) NSUInteger numbersOffset;
@property (nonatomic, strong) NSMutableDictionary *queuedSegments;
@property (nonatomic) NSUInteger nextSegmentIndexToUpload;
@property (nonatomic, strong) AWSS3TransferManager *transferManager;
@property (nonatomic, strong) AWSS3 *s3;
@property (nonatomic, strong) KFDirectoryWatcher *directoryWatcher;
@property (atomic, strong) NSMutableDictionary *files;
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
        
        AWSRegionType region = [KFAWSCredentialsProvider regionTypeForRegion:stream.awsRegion];
        KFAWSCredentialsProvider *awsCredentialsProvider = [[KFAWSCredentialsProvider alloc] initWithStream:stream];
        AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:region
                                                                             credentialsProvider:awsCredentialsProvider];
        
        [AWSS3TransferManager registerS3TransferManagerWithConfiguration:configuration forKey:kKFS3TransferManagerKey];
        [AWSS3 registerS3WithConfiguration:configuration forKey:kKFS3Key];
        
        self.transferManager = [AWSS3TransferManager S3TransferManagerForKey:kKFS3TransferManagerKey];
        self.s3 = [AWSS3 S3ForKey:kKFS3Key];
        
        self.manifestGenerator = [[KFHLSManifestGenerator alloc] initWithTargetDuration:10 playlistType:KFHLSManifestPlaylistTypeVOD];
    }
    return self;
}

- (void) finishedRecording {
    self.isFinishedRecording = YES;
    if (!self.hasUploadedFinalManifest) {
        NSString *manifestSnapshot = [self manifestSnapshot];
        DDLogInfo(@"final manifest snapshot: %@", manifestSnapshot);
        [self.manifestGenerator appendFromLiveManifest:manifestSnapshot];
        [self.manifestGenerator finalizeManifest];
        NSString *manifestString = [self.manifestGenerator manifestString];
        [self updateManifestWithString:manifestString manifestName:kVODManifestFileName];
    }
}

- (void) setUseSSL:(BOOL)useSSL {
    _useSSL = useSSL;
}

- (void) uploadNextSegment {
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.directoryPath error:nil];
    NSUInteger tsFileCount = 0;
    for (NSString *fileName in contents) {
        if ([[fileName pathExtension] isEqualToString:@"ts"]) {
            tsFileCount++;
        }
    }

    
    NSDictionary *segmentInfo = [_queuedSegments objectForKey:@(_nextSegmentIndexToUpload)];
    
    // Skip uploading files that are currently being written
    if (tsFileCount == 1 && !self.isFinishedRecording) {
        DDLogInfo(@"Skipping upload of ts file currently being recorded: %@ %@", segmentInfo, contents);
        return;
    }
    
    NSString *fileName = [segmentInfo objectForKey:kFileNameKey];
    NSString *fileUploadState = [_files objectForKey:fileName];
    if (![fileUploadState isEqualToString:kUploadStateQueued]) {
        DDLogVerbose(@"Trying to upload file that isn't queued (%@): %@", fileUploadState, segmentInfo);
        return;
    }
    [_files setObject:kUploadStateUploading forKey:fileName];
    NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];
    NSString *key = [self awsKeyForStream:self.stream fileName:fileName];
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = self.stream.bucketName;
    uploadRequest.key = key;
    uploadRequest.body = [NSURL fileURLWithPath:filePath];
    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    
    [[self.transferManager upload:uploadRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            [self s3RequestFailedForFileName:fileName withError:task.error];
        } else {
            [self s3RequestCompletedForFileName:fileName];
        }
        return nil;
    }];

}

- (NSString*) awsKeyForStream:(KFS3Stream*)stream fileName:(NSString*)fileName {
    return [NSString stringWithFormat:@"%@%@", stream.awsPrefix, fileName];
}

- (void) updateManifestWithString:(NSString*)manifestString manifestName:(NSString*)manifestName {
    NSData *data = [manifestString dataUsingEncoding:NSUTF8StringEncoding];
    DDLogVerbose(@"New manifest:\n%@", manifestString);
    NSString *key = [self awsKeyForStream:self.stream fileName:manifestName];
    
    AWSS3PutObjectRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
    uploadRequest.bucket = self.stream.bucketName;
    uploadRequest.key = key;
    uploadRequest.body = data;
    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    uploadRequest.cacheControl = @"max-age=0";
    uploadRequest.contentLength = @(data.length);
    
    [[self.s3 putObject:uploadRequest] continueWithBlock:^id(BFTask *task) {
        if (task.error) {
            [self s3RequestFailedForFileName:manifestName withError:task.error];
        } else {
            [self s3RequestCompletedForFileName:manifestName];
        }
        return nil;
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
                [self.manifestGenerator appendFromLiveManifest:manifestSnapshot];
                NSUInteger segmentIndex = [self indexForFilePrefix:filePrefix];
                NSDictionary *segmentInfo = @{kManifestKey: manifestSnapshot,
                                              kFileNameKey: fileName,
                                              kFileStartDateKey: [NSDate date]};
                DDLogVerbose(@"new ts file detected: %@", fileName);
                [_files setObject:kUploadStateQueued forKey:fileName];
                [_queuedSegments setObject:segmentInfo forKey:@(segmentIndex)];
                [self uploadNextSegment];
            }
        } else if ([fileExtension isEqualToString:@"jpg"]) {
            [self uploadThumbnail:fileName];
        }
    }];
}

- (void) uploadThumbnail:(NSString*)fileName {
    NSString *uploadState = [_files objectForKey:fileName];
    if (![uploadState isEqualToString:kUploadStateFinished]) {
        NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];
        NSString *key = [self awsKeyForStream:self.stream fileName:fileName];

        AWSS3TransferManagerUploadRequest *uploadRequest = [AWSS3TransferManagerUploadRequest new];
        uploadRequest.bucket = self.stream.bucketName;
        uploadRequest.key = key;
        uploadRequest.body = [NSURL fileURLWithPath:filePath];
        uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
        
        [[self.transferManager upload:uploadRequest] continueWithBlock:^id(BFTask *task) {
            if (task.error) {
                [self s3RequestFailedForFileName:fileName withError:task.error];
            } else {
                [self s3RequestCompletedForFileName:fileName];
            }
            return nil;
        }];
    }
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
    NSString *manifestName = nil;
    if (self.isFinishedRecording) {
        manifestName = kVODManifestFileName;
    } else {
        manifestName = [_manifestPath lastPathComponent];
    }
    return [self urlWithFileName:manifestName];
}

-(void)s3RequestCompletedForFileName:(NSString*)fileName
{
    dispatch_async(_scanningQueue, ^{
        if ([fileName.pathExtension isEqualToString:@"m3u8"]) {
            dispatch_async(self.callbackQueue, ^{
                if (!_manifestReady) {
                    if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:liveManifestReadyAtURL:)]) {
                        [self.delegate uploader:self liveManifestReadyAtURL:[self manifestURL]];
                    }
                    _manifestReady = YES;
                }
                if (self.isFinishedRecording && _queuedSegments.count == 0) {
                    self.hasUploadedFinalManifest = YES;
                    if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:vodManifestReadyAtURL:)]) {
                        [self.delegate uploader:self vodManifestReadyAtURL:[self manifestURL]];
                    }
                    if (self.delegate && [self.delegate respondsToSelector:@selector(uploaderHasFinished:)]) {
                        [self.delegate uploaderHasFinished:self];
                    }
                }
            });
        } else if ([fileName.pathExtension isEqualToString:@"ts"]) {
            NSDictionary *segmentInfo = [_queuedSegments objectForKey:@(_nextSegmentIndexToUpload)];
            NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];

            NSString *manifest = [segmentInfo objectForKey:kManifestKey];
            NSDate *uploadStartDate = [segmentInfo objectForKey:kFileStartDateKey];

            NSDate *uploadFinishDate = [NSDate date];
            
            NSError *error = nil;
            NSDictionary *fileStats = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:&error];
            if (error) {
                DDLogError(@"Error getting stats of path %@: %@", filePath, error);
            }
            uint64_t fileSize = [fileStats fileSize];
            
            NSTimeInterval timeToUpload = [uploadFinishDate timeIntervalSinceDate:uploadStartDate];
            double bytesPerSecond = fileSize / timeToUpload;
            double KBps = bytesPerSecond / 1024;
            [_files setObject:kUploadStateFinished forKey:fileName];

            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                DDLogError(@"Error removing uploaded segment: %@", error.description);
            }
            [_queuedSegments removeObjectForKey:@(_nextSegmentIndexToUpload)];
            NSUInteger queuedSegmentsCount = _queuedSegments.count;
            [self updateManifestWithString:manifest manifestName:@"index.m3u8"];
            _nextSegmentIndexToUpload++;
            [self uploadNextSegment];
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:didUploadSegmentAtURL:uploadSpeed:numberOfQueuedSegments:)]) {
                NSURL *url = [self urlWithFileName:fileName];
                dispatch_async(self.callbackQueue, ^{
                    [self.delegate uploader:self didUploadSegmentAtURL:url uploadSpeed:KBps numberOfQueuedSegments:queuedSegmentsCount];
                });
            }
        } else if ([fileName.pathExtension isEqualToString:@"jpg"]) {
            [self.files setObject:kUploadStateFinished forKey:fileName];
            if (self.delegate && [self.delegate respondsToSelector:@selector(uploader:thumbnailReadyAtURL:)]) {
                NSURL *url = [self urlWithFileName:fileName];
                dispatch_async(self.callbackQueue, ^{
                    [self.delegate uploader:self thumbnailReadyAtURL:url];
                });
            }
            NSString *filePath = [_directoryPath stringByAppendingPathComponent:fileName];
            
            NSError *error = nil;
            [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
            if (error) {
                DDLogError(@"Error removing thumbnail: %@", error.description);
            }
            self.stream.thumbnailURL = [self urlWithFileName:fileName];
            [[KFAPIClient sharedClient] updateMetadataForStream:self.stream callbackBlock:^(KFStream *updatedStream, NSError *error) {
                if (error) {
                    DDLogError(@"Error updating stream thumbnail: %@", error);
                } else {
                    DDLogInfo(@"Updated stream thumbnail: %@", updatedStream.thumbnailURL);
                }
            }];
        }
    });
}

-(void)s3RequestFailedForFileName:(NSString*)fileName withError:(NSError *)error
{
    dispatch_async(_scanningQueue, ^{
        [_files setObject:kUploadStateFailed forKey:fileName];
        DDLogError(@"Failed to upload request, requeuing %@: %@", fileName, error.description);
        [self uploadNextSegment];
    });
}

@end
