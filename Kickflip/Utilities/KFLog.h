//
//  KFLog.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/22/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#ifndef KFLog_h
#define KFLog_h

#import <CocoaLumberjack/CocoaLumberjack.h>

#define LOG_LEVEL_DEF ddKickflipLogLevel

#ifdef DEBUG
static const DDLogLevel ddKickflipLogLevel = DDLogLevelDebug;
#else
static const DDLogLevel ddKickflipLogLevel = DDLogLevelOff;
#endif

#endif