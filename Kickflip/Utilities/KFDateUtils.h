//
//  KFDateUtils.h
//  Pods
//
//  Created by Christopher Ballinger on 4/4/14.
//
//

#import <Foundation/Foundation.h>

@interface KFDateUtils : NSObject

+ (NSDateFormatter*)utcDateFormatter;
+ (NSDateFormatter*)localizedDateFormatter;

@end
