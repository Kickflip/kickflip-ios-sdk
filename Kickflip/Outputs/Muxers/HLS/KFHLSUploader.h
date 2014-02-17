//
//  KFHLSUploader.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/20/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFDirectoryWatcher.h"

@class OWS3Client, KFS3Endpoint;

@interface KFHLSUploader : NSObject <KFDirectoryWatcherDelegate>

@property (nonatomic, strong) KFDirectoryWatcher *directoryWatcher;
@property (nonatomic, strong) NSString *directoryPath;
@property (nonatomic, strong) NSMutableDictionary *files;
@property (nonatomic, strong) NSString *manifestPath;
@property (nonatomic, strong) NSString *remoteFolderName;
@property (nonatomic) dispatch_queue_t scanningQueue;
@property (nonatomic, strong) OWS3Client *s3Client;
@property (nonatomic, strong) KFS3Endpoint *endpoint;

- (id) initWithDirectoryPath:(NSString*)directoryPath endpoint:(KFS3Endpoint*)endpoint;

- (NSURL*) manifestURL;

@end
