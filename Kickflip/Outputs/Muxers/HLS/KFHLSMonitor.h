//
//  KFHLSMonitor.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KFS3EndpointResponse;

@interface KFHLSMonitor : NSObject

+ (KFHLSMonitor*) sharedMonitor;

- (void) monitorFolderPath:(NSString*)path endpoint:(KFS3EndpointResponse*)endpoint;

@end
