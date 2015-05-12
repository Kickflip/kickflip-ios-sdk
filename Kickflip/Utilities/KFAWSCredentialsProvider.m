//
//  KFAWSCredentialsProvider.m
//  Pods
//
//  Created by Christopher Ballinger on 5/11/15.
//
//

#import "KFAWSCredentialsProvider.h"
#import <Bolts/BFTask.h>

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
- (BFTask *)refresh {
    return [BFTask taskWithError:[NSError errorWithDomain:@"io.kickflip.sdk" code:100 userInfo:@{NSLocalizedDescriptionKey: @"Refresh not supported"}]];
}

@end
