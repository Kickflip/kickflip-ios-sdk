//
//  RTSPClientConnection.h
//  Encoder Demo
//
//  Created by Geraint Davies on 24/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import <Foundation/Foundation.h>
#import "RTSPServer.h"

@interface RTSPClientConnection : NSObject


+ (RTSPClientConnection*) createWithSocket:(CFSocketNativeHandle) s server:(RTSPServer*) server;

- (void) onVideoData:(NSArray*) data time:(double) pts;
- (void) shutdown;

@end
