//
//  KFDateUtils.h
//  Pods
//
//  Created by Christopher Ballinger on 4/4/14.
//
//

#import <Foundation/Foundation.h>
#import "TTTTimeIntervalFormatter.h"

@interface KFDateUtils : NSObject

+ (NSDateFormatter*)utcDateFormatter;
+ (NSDateFormatter*)localizedDateFormatter;
+ (TTTTimeIntervalFormatter*)timeIntervalFormatter;
+ (NSString *)timeIntervalStringFromDate:(NSDate *)startDate toDate:(NSDate*)endDate;

@end
