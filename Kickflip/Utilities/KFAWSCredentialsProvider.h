//
//  KFAWSCredentialsProvider.h
//  Pods
//
//  Created by Christopher Ballinger on 5/11/15.
//
//

#import <Foundation/Foundation.h>
#import <AWSCore/AWSCore.h>
#import "KFS3Stream.h"

@interface KFAWSCredentialsProvider : NSObject <AWSCredentialsProvider>

/**
 *  Access Key component of credentials.
 */
@property (nonatomic, strong, readonly) NSString *accessKey;

/**
 *  Secret Access Key component of credentials.
 */
@property (nonatomic, strong, readonly) NSString *secretKey;

/**
 *  Session Token component of credentials.
 */
@property (nonatomic, strong, readonly) NSString *sessionKey;

/**
 *  Date at which these credentials will expire.
 */
@property (nonatomic, strong, readonly) NSDate *expiration;

/**
 *  Refresh the token associated with this provider.
 *
 *  *Note* This method is automatically called by the AWS Mobile SDK for iOS, and you do not need to call this method in general.
 *
 *  @return BFTask.
 */
- (AWSTask *)refresh;

- (instancetype)initWithStream:(KFS3Stream*)stream;

/** Utility to convert from "us-west-1" to enum AWSRegionUSWest1 */
+ (AWSRegionType) regionTypeForRegion:(NSString*)region;

@end
