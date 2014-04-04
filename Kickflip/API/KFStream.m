//
//  KFStream.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFStream.h"
#import "KFDateUtils.h"

const struct KFStreamAttributes KFStreamAttributes = {
    .streamType = @"streamType",
	.streamID = @"streamID",
	.uploadURL = @"uploadURL",
    .streamURL = @"streamURL",
    .kickflipURL = @"kickflipURL",
    .username = @"username",
    .startDate = @"startDate",
    .finishDate = @"finishDate"
};

NSString * const KFStreamTypeKey = @"stream_type";
static NSString * const KFStreamIDKey = @"stream_id";
static NSString * const KFStreamUploadURLKey = @"upload_url";
static NSString * const KFStreamURLKey = @"stream_url";
static NSString * const KFStreamKickflipURLKey = @"kickflip_url";
static NSString * const KFStreamStateKey = @"KFStreamStateKey";

@implementation KFStream

+ (NSDictionary*) JSONKeyPathsByPropertyKey {
    return @{KFStreamAttributes.streamType: KFStreamTypeKey,
             KFStreamAttributes.streamID: KFStreamIDKey,
             KFStreamAttributes.uploadURL: KFStreamUploadURLKey,
             KFStreamAttributes.streamURL: KFStreamURLKey,
             KFStreamAttributes.kickflipURL: KFStreamKickflipURLKey,
             KFStreamAttributes.username: @"user_username",
             KFStreamAttributes.startDate: @"time_started",
             KFStreamAttributes.finishDate: @"time_finished"};
}

+ (NSValueTransformer *)uploadURLJSONTransformer {
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
