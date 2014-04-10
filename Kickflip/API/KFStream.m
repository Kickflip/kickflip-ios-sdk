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

@interface KFStream()
@property (nonatomic, strong, readonly) NSNumber *startLatitude;
@property (nonatomic, strong, readonly) NSNumber *startLongitude;
@property (nonatomic, strong, readonly) NSNumber *endLatitude;
@property (nonatomic, strong, readonly) NSNumber *endLongitude;
@end

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
             NSStringFromSelector(@selector(country)): @"country",
             NSStringFromSelector(@selector(startLatitude)): @"start_lat",
             NSStringFromSelector(@selector(startLongitude)): @"start_lon",
             NSStringFromSelector(@selector(endLatitude)): @"end_lat",
             NSStringFromSelector(@selector(endLongitude)): @"end_lon",
             NSStringFromSelector(@selector(startLocation)): [NSNull null],
             NSStringFromSelector(@selector(endLocation)): [NSNull null],
             NSStringFromSelector(@selector(streamState)): [NSNull null]};
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

- (void) setStartLocation:(CLLocation *)startLocation {
    if (!startLocation) {
        return;
    }
    _startLatitude = @(startLocation.coordinate.latitude);
    _startLongitude = @(startLocation.coordinate.longitude);
}

- (void) setEndLocation:(CLLocation *)endLocation {
    if (!endLocation) {
        return;
    }
    _endLatitude = @(endLocation.coordinate.latitude);
    _endLongitude = @(endLocation.coordinate.longitude);
}

- (CLLocation*) startLocation {
    if (!self.startLatitude || !self.startLongitude) {
        return nil;
    }
    return [[CLLocation alloc] initWithLatitude:self.startLatitude.doubleValue longitude:self.startLongitude.doubleValue];
}

- (CLLocation*) endLocation {
    if (!self.endLatitude || !self.endLongitude) {
        return nil;
    }
    return [[CLLocation alloc] initWithLatitude:self.endLatitude.doubleValue longitude:self.endLongitude.doubleValue];
}

- (BOOL) isLive {
    if (self.startDate && !self.finishDate) {
        return YES;
    }
    if ([self.startDate isEqualToDate:self.finishDate]) {
        return YES;
    }
    return NO;
}

@end
