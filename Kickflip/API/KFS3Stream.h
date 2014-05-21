//
//  KFS3Stream.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFStream.h"

extern const struct KFS3StreamAttributes {
    __unsafe_unretained NSString *bucketName;
	__unsafe_unretained NSString *awsAccessKey;
	__unsafe_unretained NSString *awsSecretKey;
    __unsafe_unretained NSString *awsPrefix;
} KFS3StreamAttributes;

extern NSString * const KFS3StreamType;

@interface KFS3Stream : KFStream

@property (nonatomic, strong) NSString *bucketName;
@property (nonatomic, strong) NSString *awsAccessKey;
@property (nonatomic, strong) NSString *awsSecretKey;
@property (nonatomic, strong) NSString *awsPrefix;

@end
