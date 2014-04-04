//
//  KFDateUtils.m
//  Pods
//
//  Created by Christopher Ballinger on 4/4/14.
//
//

#import "KFDateUtils.h"

@implementation KFDateUtils

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"dd/MM/yyyy' 'HH:mm:ss";
        dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    });
    return dateFormatter;
}

@end
