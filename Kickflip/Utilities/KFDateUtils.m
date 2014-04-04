//
//  KFDateUtils.m
//  Pods
//
//  Created by Christopher Ballinger on 4/4/14.
//
//

#import "KFDateUtils.h"

@implementation KFDateUtils

+ (NSDateFormatter *)utcDateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"MM/dd/yyyy' 'HH:mm:ss";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return dateFormatter;
}

+ (NSDateFormatter*) localizedDateFormatter {
    static NSDateFormatter *humanizedDateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        humanizedDateFormatter = [[NSDateFormatter alloc] init];
        humanizedDateFormatter.dateStyle = NSDateFormatterMediumStyle;
        humanizedDateFormatter.timeStyle = NSDateFormatterShortStyle;
        humanizedDateFormatter.timeZone = [NSTimeZone localTimeZone];
        humanizedDateFormatter.locale = [NSLocale currentLocale];
    });
    return humanizedDateFormatter;
}

@end
