//
//  KFS3Stream.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFStream.h"

extern NSString * const KFS3StreamType;

@interface KFS3Stream : KFStream

@property (nonatomic, strong) NSString *bucketName;
@property (nonatomic, strong) NSString *awsAccessKey;
@property (nonatomic, strong) NSString *awsSecretKey;
@property (nonatomic, strong) NSString *awsSessionToken;
@property (nonatomic, strong) NSDate *awsExpirationDate;
@property (nonatomic, strong) NSString *awsPrefix;
@property (nonatomic, strong) NSString *awsRegion;

@end
