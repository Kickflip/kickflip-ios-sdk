//
//  OWSharedS3Client.m
//  LiveStreamer
//
//  Created by Christopher Ballinger on 10/4/13.
//  Copyright (c) 2013 OpenWatch, Inc. All rights reserved.
//

#import "OWSharedS3Client.h"
#import "KFSecrets.h"

@implementation OWSharedS3Client

+ (OWSharedS3Client*) sharedClient {
    static OWSharedS3Client *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OWSharedS3Client alloc] init];
    });
    return _sharedInstance;
}

- (id) init {
    if (self = [super initWithAccessKey:AWS_ACCESS_KEY_ID secretKey:AWS_SECRET_KEY]) {
        self.region = US_EAST_1;
        self.useSSL = NO;
    }
    return self;
}

@end
