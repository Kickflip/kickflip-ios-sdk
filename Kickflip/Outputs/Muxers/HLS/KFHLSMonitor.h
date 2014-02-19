//
//  KFHLSMonitor.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KFHLSUploader.h"


@interface KFHLSMonitor : NSObject <KFHLSUploaderDelegate>

+ (KFHLSMonitor*) sharedMonitor;

- (void) startMonitoringFolderPath:(NSString*)path endpoint:(KFS3Stream*)endpoint delegate:(id<KFHLSUploaderDelegate>)delegate;
- (void) finishUploadingContentsAtFolderPath:(NSString*)path endpoint:(KFS3Stream*)endpoint; //reclaims delegate of uploader

@end
