//
//  KFS3Uploader.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFUploader.h"
#import "KFHLSMonitor.h"

@interface KFS3Uploader : KFUploader

@property (nonatomic, strong) KFHLSMonitor *monitor;

@end
