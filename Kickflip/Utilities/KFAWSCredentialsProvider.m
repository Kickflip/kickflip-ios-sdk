//
//  KFAWSCredentialsProvider.m
//  Pods
//
//  Created by Christopher Ballinger on 5/11/15.
//
//

#import "KFAWSCredentialsProvider.h"
#import <AWSCore/AWSCore.h>

@implementation KFAWSCredentialsProvider

- (instancetype)initWithStream:(KFS3Stream*)stream {
    if (self = [super init]) {
        _accessKey = stream.awsAccessKey;
        _secretKey = stream.awsSecretKey;
        _sessionKey = stream.awsSessionToken;
        _expiration = stream.awsExpirationDate;
    }
    return self;
}

/**
 *  Refresh the token associated with this provider.
 *
 *  *Note* This method is automatically called by the AWS Mobile SDK for iOS, and you do not need to call this method in general.
 *
 *  @return BFTask.
 */
- (AWSTask *)refresh {
    return [AWSTask taskWithError:[NSError errorWithDomain:@"io.kickflip.sdk" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Refresh not supported"}]];
}

/** Utility to convert from "us-west-1" to enum AWSRegionUSWest1 */
+ (AWSRegionType) regionTypeForRegion:(NSString*)region {
    AWSRegionType regionType = AWSRegionUnknown;
    if ([region isEqualToString:@"us-east-1"]) {
        regionType = AWSRegionUSEast1;
    } else if ([region isEqualToString:@"us-west-1"]) {
        regionType = AWSRegionUSWest1;
    } else if ([region isEqualToString:@"us-west-2"]) {
        regionType = AWSRegionUSWest2;
    } else if ([region isEqualToString:@"eu-west-1"]) {
        regionType = AWSRegionEUWest1;
    } else if ([region isEqualToString:@"us-central-1"]) {
        regionType = AWSRegionEUCentral1;
    } else if ([region isEqualToString:@"ap-southeast-1"]) {
        regionType = AWSRegionAPSoutheast1;
    } else if ([region isEqualToString:@"ap-southeast-2"]) {
        regionType = AWSRegionAPSoutheast2;
    } else if ([region isEqualToString:@"ap-northeast-1"]) {
        regionType = AWSRegionAPNortheast1;
    } else if ([region isEqualToString:@"sa-east-1"]) {
        regionType = AWSRegionSAEast1;
    } else if ([region isEqualToString:@"cn-north-1"]) {
        regionType = AWSRegionCNNorth1;
    }
    return regionType;
}

@end
