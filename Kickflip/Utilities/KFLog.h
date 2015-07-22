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

    #ifndef LOG_LEVEL_DEF

        #ifdef DEBUG
            #define LOG_LEVEL_DEF DDLogLevelInfo
        #else
            #define LOG_LEVEL_DEF DDLogLevelOff
        #endif
    #endif

#endif
