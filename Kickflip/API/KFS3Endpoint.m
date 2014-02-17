//
//  KFS3Endpoint.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFS3Endpoint.h"
#import "KFUser.h"

NSString * const KFS3EndpointStreamType = @"HLS";
static NSString * const KFS3EndpointBucketNameKey = @"bucket_name";
static NSString * const KFS3EndpointAWSAccessKey = @"aws_access_key";
static NSString * const KFS3EndpointAWSSecretKey = @"aws_secret_key";

@interface KFS3Endpoint()
@end

@implementation KFS3Endpoint

- (instancetype) initWithUser:(KFUser *)user parameters:(NSDictionary *)parameters {
    if (self = [super initWithUser:user parameters:parameters]) {
        self.bucketName = parameters[KFS3EndpointBucketNameKey];
        self.awsAccessKey = parameters[KFS3EndpointAWSAccessKey];
        self.awsSecretKey = parameters[KFS3EndpointAWSSecretKey];
    }
    return self;
}


@end
