//
//  KFS3Stream.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFS3Stream.h"
#import "KFUser.h"

NSString * const KFS3StreamType = @"HLS";
static NSString * const KFS3StreamBucketNameKey = @"bucket_name";
static NSString * const KFS3StreamAWSAccessKey = @"aws_access_key";
static NSString * const KFS3StreamAWSSecretKey = @"aws_secret_key";

@interface KFS3Stream()
@end

@implementation KFS3Stream

- (instancetype) initWithUser:(KFUser *)user parameters:(NSDictionary *)parameters {
    if (self = [super initWithUser:user parameters:parameters]) {
        self.bucketName = parameters[KFS3StreamBucketNameKey];
        self.awsAccessKey = parameters[KFS3StreamAWSAccessKey];
        self.awsSecretKey = parameters[KFS3StreamAWSSecretKey];
    }
    return self;
}

- (NSDictionary*) dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[super dictionaryRepresentation]];
    if (self.bucketName) {
        [dict setObject:self.bucketName forKey:KFS3StreamBucketNameKey];
    }
    if (self.awsAccessKey) {
        [dict setObject:self.awsAccessKey forKey:KFS3StreamAWSAccessKey];
    }
    if (self.awsSecretKey) {
        [dict setObject:self.awsSecretKey forKey:KFS3StreamAWSSecretKey];
    }
    return dict;
}


@end
