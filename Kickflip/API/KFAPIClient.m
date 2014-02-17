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
#import "KFS3Endpoint.h"
#import "Kickflip.h"

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
        
        
        
        [self checkOAuthCredentialsWithCallback:nil];
    }
    return self;
}

- (void) checkOAuthCredentialsWithCallback:(void (^)(BOOL success, NSError * error))callback {
    NSURL *url = [NSURL URLWithString:KICKFLIP_API_BASE_URL];
    NSString *apiKey = [Kickflip apiKey];
    NSString *apiSecret = [Kickflip apiSecret];
    if (!apiKey || !apiSecret) {
        callback(NO, [NSError errorWithDomain:kKFAPIClientErrorDomain code:99 userInfo:@{NSLocalizedDescriptionKey: @"Missing API key and secret.", NSLocalizedRecoverySuggestionErrorKey: @"Call [Kickflip setupWithAPIKey:secret:] with your credentials obtained from kickflip.io"}]);
        return;
    }
    AFOAuth2Client *oauthClient = [AFOAuth2Client clientWithBaseURL:url clientID:apiKey secret:apiSecret];
    
    AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:oauthClient.serviceProviderIdentifier];
    if (credential && !credential.isExpired) {
        [self setAuthorizationHeaderWithCredential:credential];
        if (callback) {
            callback(YES, nil);
        }
        return;
    }

    [oauthClient authenticateUsingOAuthWithPath:@"/o/token/" parameters:@{@"grant_type": kAFOAuthClientCredentialsGrantType} success:^(AFOAuthCredential *credential) {
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

- (void) requestNewUser:(void (^)(KFUser *newUser, NSError *error))userCallback {
    [self checkOAuthCredentialsWithCallback:^(BOOL success, NSError *error) {
        if (!success) {
            if (userCallback) {
                userCallback(nil, error);
            }
            return;
        }
        [self postPath:@"/api/new/user/" parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
            if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *responseDictionary = (NSDictionary*)responseObject;
                KFUser *activeUser = [KFUser activeUserWithDictionary:responseDictionary];
                if (!userCallback) {
                    return;
                }
                if (!activeUser) {
                    userCallback(nil, [NSError errorWithDomain:kKFAPIClientErrorDomain code:100 userInfo:@{NSLocalizedDescriptionKey: @"User response error, no user", @"operation": operation}]);
                    return;
                }
                userCallback(activeUser, nil);
            } else {
                if (userCallback) {
                    userCallback(nil, [NSError errorWithDomain:kKFAPIClientErrorDomain code:101 userInfo:@{NSLocalizedDescriptionKey: @"User response error, bad server response", @"operation": operation}]);
                }
            }
            
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if (error && userCallback) {
                userCallback(nil, error);
            }
        }];
    }];
}

- (void) requestNewEndpointWithUser:(KFUser*)user callback:(void (^)(KFEndpoint *endpoint, NSError *error))endpointCallback {
    [self postPath:@"/api/stream/start" parameters:@{@"uuid": user.uuid} success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *responseDictionary = (NSDictionary*)responseObject;
            if (![[responseDictionary objectForKey:@"success"] boolValue]) {
                if (endpointCallback) {
                    NSError *error = [NSError errorWithDomain:kKFAPIClientErrorDomain code:103 userInfo:@{NSLocalizedDescriptionKey: @"Bad request", @"response": responseObject}];
                    endpointCallback(nil, error);
                }
                return;
            }
            KFEndpoint *endpoint = nil;
            NSString *streamType = responseDictionary[KFEndpointStreamTypeKey];
            if ([streamType isEqualToString:KFS3EndpointStreamType]) {
                endpoint = [[KFS3Endpoint alloc] initWithUser:user parameters:responseDictionary];
            }
            
            if (endpoint) {
                endpointCallback(endpointCallback, nil);
            } else {
                endpointCallback(nil, [NSError errorWithDomain:kKFAPIClientErrorDomain code:104 userInfo:@{NSLocalizedDescriptionKey: @"Error parsing response", @"response": responseDictionary}]);
            }
        } else {
            if (endpointCallback) {
                NSError *error = [NSError errorWithDomain:kKFAPIClientErrorDomain code:103 userInfo:@{NSLocalizedDescriptionKey: @"Bad request", @"response": responseObject}];
                endpointCallback(nil, error);
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (endpointCallback) {
            endpointCallback(nil, error);
        }
    }];
}

- (void) requestNewEndpoint:(void (^)(KFEndpoint *, NSError *))endpointCallback {
    [self checkOAuthCredentialsWithCallback:^(BOOL success, NSError *error) {
        if (!success) {
            if (endpointCallback) {
                endpointCallback(nil, error);
            }
            return;
        }
        KFUser *activeUser = [KFUser activeUser];
        if (activeUser) {
            [self requestNewEndpointWithUser:activeUser callback:endpointCallback];
            return;
        }
        [self requestNewUser:^(KFUser *newUser, NSError *error) {
            if (error) {
                if (endpointCallback) {
                    endpointCallback(nil, error);
                }
                return;
            }
            [self requestNewEndpointWithUser:newUser callback:endpointCallback];
        }];
    }];
}


@end
