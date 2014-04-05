//
//  KFStream.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFStream.h"
#import "KFDateUtils.h"

NSString * const KFStreamTypeKey = @"stream_type";
static NSString * const KFStreamIDKey = @"stream_id";
static NSString * const KFStreamUploadURLKey = @"upload_url";
static NSString * const KFStreamURLKey = @"stream_url";
static NSString * const KFStreamKickflipURLKey = @"kickflip_url";
static NSString * const KFStreamStateKey = @"KFStreamStateKey";

@implementation KFStream

+ (NSDictionary*) JSONKeyPathsByPropertyKey {
    return @{NSStringFromSelector(@selector(streamType)): KFStreamTypeKey,
             NSStringFromSelector(@selector(streamID)): KFStreamIDKey,
             NSStringFromSelector(@selector(uploadURL)): KFStreamUploadURLKey,
             NSStringFromSelector(@selector(streamURL)): KFStreamURLKey,
             NSStringFromSelector(@selector(kickflipURL)): KFStreamKickflipURLKey,
             NSStringFromSelector(@selector(username)): @"user_username",
             NSStringFromSelector(@selector(startDate)): @"time_started",
             NSStringFromSelector(@selector(finishDate)): @"time_finished",
             NSStringFromSelector(@selector(thumbnailURL)): @"thumbnail_url",
             NSStringFromSelector(@selector(city)): @"city",
             NSStringFromSelector(@selector(state)): @"state",
             NSStringFromSelector(@selector(country)): @"country"};
}

+ (NSValueTransformer *)uploadURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)thumbnailURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)kickflipURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)streamURLJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)startDateJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return [[KFDateUtils utcDateFormatter] dateFromString:str];
    } reverseBlock:^(NSDate *date) {
        return [[KFDateUtils utcDateFormatter] stringFromDate:date];
    }];
}

+ (NSValueTransformer *)finishDateJSONTransformer {
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSString *str) {
        return [[KFDateUtils utcDateFormatter] dateFromString:str];
    } reverseBlock:^(NSDate *date) {
        return [[KFDateUtils utcDateFormatter] stringFromDate:date];
    }];
}

@end
