//
//  KFHLSUploader.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/20/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFDirectoryWatcher.h"

@class OWS3Client, KFS3Stream;

@interface KFHLSUploader : NSObject <KFDirectoryWatcherDelegate>

@property (nonatomic, strong) KFDirectoryWatcher *directoryWatcher;
@property (nonatomic, strong) NSString *directoryPath;
@property (nonatomic, strong) NSMutableDictionary *files;
@property (nonatomic, strong) NSString *manifestPath;
@property (nonatomic) dispatch_queue_t scanningQueue;
@property (nonatomic, strong) OWS3Client *s3Client;
@property (nonatomic, strong) KFS3Stream *stream;

- (id) initWithDirectoryPath:(NSString*)directoryPath stream:(KFS3Stream*)stream;

- (NSURL*) manifestURLWithSSL:(BOOL)withSSL;

@end
