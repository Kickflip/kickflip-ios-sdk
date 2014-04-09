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


+ (TTTTimeIntervalFormatter*) timeIntervalFormatter {
    static TTTTimeIntervalFormatter *timeFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        timeFormatter = [[TTTTimeIntervalFormatter alloc] init];
    });
    return timeFormatter;
}

+ (NSString*) timeIntervalStringFromDate:(NSDate *)startDate toDate:(NSDate *)endDate {
    if (!startDate || !endDate) {
        return nil;
    }
    NSCalendarUnit calendarUnits = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    NSDateComponents *dateComponents = [currentCalendar components:calendarUnits fromDate:startDate toDate:endDate options:0];
    
    NSInteger numHours = [dateComponents hour];
    NSInteger numMinutes = [dateComponents minute];
    NSInteger numSeconds = [dateComponents second];
    NSMutableString *timeIntervalString = [NSMutableString string];
    NSMutableArray *stringComponents = [NSMutableArray arrayWithCapacity:3];
    if (numHours > 0) {
        NSString *hours = [NSString stringWithFormat:@"%dh", (int)numHours];
        [stringComponents addObject:hours];
    }
    if (numMinutes > 0) {
        NSString *minutes = [NSString stringWithFormat:@"%dm", (int)numMinutes];
        [stringComponents addObject:minutes];
    }
    if (numSeconds > 0) {
        NSString *seconds = [NSString stringWithFormat:@"%ds", (int)numSeconds];
        [stringComponents addObject:seconds];
    }
    for (int i = 0; i < stringComponents.count; i++) {
        NSString *component = [stringComponents objectAtIndex:i];
        [timeIntervalString appendFormat:@"%@", component];
        if (i < stringComponents.count - 1) {
            [timeIntervalString appendString:@" "];
        }
    }
    
    return timeIntervalString;
}



@end
