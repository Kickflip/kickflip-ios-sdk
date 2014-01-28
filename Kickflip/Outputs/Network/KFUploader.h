//
//  KFUploader.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KFUploader;

@protocol KFUploaderDelegate <NSObject>
- (void) uploader:(KFUploader*)uploader videoReadyAtURL:(NSURL*)url;
@end

@interface KFUploader : NSObject

@end
