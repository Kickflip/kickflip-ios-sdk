//
//  KFS3Stream.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFS3Stream.h"
#import "KFUser.h"

const struct KFS3StreamAttributes KFS3StreamAttributes = {
    .bucketName = @"bucketName",
	.awsAccessKey = @"awsAccessKey",
	.awsSecretKey = @"awsSecretKey",
    .awsPrefix = @"awsPrefix"
};

NSString * const KFS3StreamType = @"HLS";
static NSString * const KFS3StreamBucketNameKey = @"bucket_name";
static NSString * const KFS3StreamAWSAccessKey = @"aws_access_key";
static NSString * const KFS3StreamAWSSecretKey = @"aws_secret_key";
static NSString * const KFS3StreamAWSPrefix = @"aws_prefix";


@interface KFS3Stream()
@end

@implementation KFS3Stream

+ (NSDictionary*) JSONKeyPathsByPropertyKey {
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithDictionary:[super JSONKeyPathsByPropertyKey]];
    dictionary[KFS3StreamAttributes.bucketName] = KFS3StreamBucketNameKey;
    dictionary[KFS3StreamAttributes.awsAccessKey] = KFS3StreamAWSAccessKey;
    dictionary[KFS3StreamAttributes.awsSecretKey] = KFS3StreamAWSSecretKey;
    dictionary[KFS3StreamAttributes.awsPrefix] = KFS3StreamAWSPrefix;
    return dictionary;
}

@end
