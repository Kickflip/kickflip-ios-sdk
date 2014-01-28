//
//  KFAPIClient.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFAPIClient.h"
#import "KFSecrets.h"
#import "AFOAuth2Client.h"
#import "KFLog.h"
#import "KFUser.h"
#import "KFS3EndpointResponse.h"

static NSString* const kKFAPIClientErrorDomain = @"kKFAPIClientErrorDomain";

@implementation KFAPIClient

+ (KFAPIClient*) sharedClient {
    static KFAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[KFAPIClient alloc] init];
    });
    return _sharedClient;
}

- (instancetype) init {
    NSURL *url = [NSURL URLWithString:KICKFLIP_API_BASE_URL];
    if (self = [super initWithBaseURL:url]) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
        
        [self checkOAuthCredentialsWithCallback:^(BOOL success, NSError *error) {
            if (success) {
                [self requestRecordingEndpoint:nil];
            }
        }];
    }
    return self;
}

- (void) checkOAuthCredentialsWithCallback:(void (^)(BOOL success, NSError * error))callback {
    NSURL *url = [NSURL URLWithString:KICKFLIP_API_BASE_URL];
    AFOAuth2Client *oauthClient = [AFOAuth2Client clientWithBaseURL:url clientID:KICKFLIP_PRODUCTION_API_ID secret:KICKFLIP_PRODUCTION_API_SECRET];
    
    AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:oauthClient.serviceProviderIdentifier];
    if (credential && !credential.isExpired) {
        [self setAuthorizationHeaderWithCredential:credential];
        if (callback) {
            callback(YES, nil);
        }
        return;
    }

    [oauthClient authenticateUsingOAuthWithPath:@"/o/token/" parameters:@{@"grant_type": kAFOAuthClientCredentialsGrantType} success:^(AFOAuthCredential *credential) {
        NSLog(@"I have new token! %@", credential.accessToken);
        [AFOAuthCredential storeCredential:credential withIdentifier:oauthClient.serviceProviderIdentifier];
        [self setAuthorizationHeaderWithCredential:credential];
        if (callback) {
            callback(YES, nil);
        }
    } failure:^(NSError *error) {
        if (callback) {
            callback(NO, error);
        }
    }];
}

- (void) setAuthorizationHeaderWithCredential:(AFOAuthCredential*)credential {
    [self setDefaultHeader:@"Authorization" value:[NSString stringWithFormat:@"Bearer %@", credential.accessToken]];
}

- (void) requestRecordingEndpoint:(void (^)(KFEndpointResponse *, NSError *))endpointCallback {
    [self checkOAuthCredentialsWithCallback:^(BOOL success, NSError *error) {
        if (!success) {
            DDLogError(@"Error fetching OAuth credentials: %@", error);
            if (endpointCallback) {
                endpointCallback(nil, error);
            }
            return;
        }
        KFUser *activeUser = [KFUser activeUser];
        if (activeUser) { // this will change when we support RTMP
            KFS3EndpointResponse *endpointResponse = [KFS3EndpointResponse endpointResponseForUser:activeUser];
            if (endpointCallback) {
                endpointCallback(endpointResponse, nil);
            }
            return;
        }
        [self postPath:@"/api/new/user/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *responseDictionary = (NSDictionary*)responseObject;
                KFUser *activeUser = [KFUser activeUserWithDictionary:responseDictionary];
                if (activeUser) {
                    KFS3EndpointResponse *endpointResponse = [KFS3EndpointResponse endpointResponseForUser:activeUser];
                    if (endpointCallback) {
                        endpointCallback(endpointResponse, nil);
                    }
                    return;
                } else {
                    if (endpointCallback) {
                        endpointCallback(nil, [NSError errorWithDomain:kKFAPIClientErrorDomain code:100 userInfo:@{NSLocalizedDescriptionKey: @"User response error", @"operation": operation}]);
                    }
                }
            } else {
                if (endpointCallback) {
                    endpointCallback(nil, [NSError errorWithDomain:kKFAPIClientErrorDomain code:100 userInfo:@{NSLocalizedDescriptionKey: @"User response error", @"operation": operation}]);
                }
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (error && endpointCallback) {
                endpointCallback(nil, error);
            }
        }];
    }];
}


@end
