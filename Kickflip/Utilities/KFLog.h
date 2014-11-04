//
//  KFLog.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/22/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#ifndef _KFLog_h
#define _KFLog_h


#import <CocoaLumberjack/CocoaLumberjack.h>

#ifdef DEBUG
static const int ddKickflipLogLevel = LOG_LEVEL_INFO;
#else
static const int ddKickflipLogLevel = LOG_LEVEL_OFF;
#endif


#ifndef LOG_LEVEL_DEF
#define LOG_LEVEL_DEF ddKickflipLogLevel
#endif


static const DDLogLevel ddLogLevel = LOG_LEVEL_VERBOSE;

#endif
