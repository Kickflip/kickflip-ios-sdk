//
//  KFS3Endpoint.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFEndpoint.h"

extern NSString * const KFS3EndpointStreamType;

@class KFUser;

@interface KFS3Endpoint : KFEndpoint

@property (nonatomic, strong) NSString *bucketName;
@property (nonatomic, strong) NSString *awsAccessKey;
@property (nonatomic, strong) NSString *awsSecretKey;

@end
