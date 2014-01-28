//
//  HLSUploader.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/20/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DirectoryWatcher.h"

@interface HLSUploader : NSObject <DirectoryWatcherDelegate>

@property (nonatomic, strong) DirectoryWatcher *directoryWatcher;
@property (nonatomic, strong) NSString *directoryPath;
@property (nonatomic, strong) NSMutableDictionary *files;
@property (nonatomic, strong) NSString *manifestPath;
@property (nonatomic, strong) NSString *remoteFolderName;
@property (nonatomic) dispatch_queue_t scanningQueue;

- (id) initWithDirectoryPath:(NSString*)directoryPath remoteFolderName:(NSString*)remoteFolderName;

- (NSURL*) manifestURL;

@end
