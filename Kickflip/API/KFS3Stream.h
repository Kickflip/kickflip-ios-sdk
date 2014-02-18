//
//  KFS3Stream.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFStream.h"

extern NSString * const KFS3StreamType;

@class KFUser;

@interface KFS3Stream : KFStream

@property (nonatomic, strong) NSString *bucketName;
@property (nonatomic, strong) NSString *awsAccessKey;
@property (nonatomic, strong) NSString *awsSecretKey;

@end
