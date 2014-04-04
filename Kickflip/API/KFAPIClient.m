//
//  KFAPIClient.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFAPIClient.h"
#import "AFOAuth2Client.h"
#import "KFLog.h"
#import "KFUser.h"
#import "KFS3Stream.h"
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
    NSURL *url = [NSURL URLWithString:@"http://api.kickflip.io/"];
    if (self = [super initWithBaseURL:url]) {
        [self registerHTTPOperationClass:[AFJSONRequestOperation class]];
        [self setDefaultHeader:@"Accept" value:@"application/json"];
        
        [self checkOAuthCredentialsWithCallback:nil];
    }
    return self;
}

- (void) checkOAuthCredentialsWithCallback:(void (^)(BOOL success, NSError * error))callback {
    NSURL *url = self.baseURL;
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

- (void) requestNewActiveUserWithUsername:(NSString*)username callbackBlock:(void (^)(KFUser *activeUser, NSError *error))callbackBlock {
    NSDictionary *parameters = nil;
    if (username) {
        parameters = @{@"username": username};
    }
    [self betterPostPath:@"/api/new/user/" parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
        if (error) {
            if (callbackBlock) {
                callbackBlock(nil, error);
            }
            return;
        }
        KFUser *user = [[KFUser alloc] initWithJSONDictionary:responseDictionary];
        [KFUser setActiveUser:user];
        if (callbackBlock) {
            callbackBlock(user, nil);
        }
    }];
}

- (void) fetchActiveUser:(void (^)(KFUser* activeUser, NSError* error))callbackBlock {
    KFUser *user = [KFUser activeUser];
    if (user) {
        callbackBlock(user, nil);
        return;
    }
    [self requestNewActiveUserWithUsername:nil callbackBlock:callbackBlock];
}

- (void) betterPostPath:(NSString*)path parameters:(NSDictionary*)parameters callbackBlock:(void (^)(NSDictionary *responseDictionary, NSError *error))callbackBlock {
    [self checkOAuthCredentialsWithCallback:^(BOOL success, NSError *error) {
        if (!success) {
            if (callbackBlock) {
                callbackBlock(nil, error);
            }
            return;
        }
        [self fetchActiveUser:^(KFUser *activeUser, NSError *error) {
            if (error) {
                callbackBlock(nil, error);
                return;
            }
            NSMutableDictionary *fullParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
            [fullParameters setObject:activeUser.uuid forKey:KFUserAttributes.uuid];
            [self postPath:path parameters:fullParameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
                if (responseObject && [responseObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *responseDictionary = (NSDictionary*)responseObject;
                    NSNumber *successValue = [responseDictionary objectForKey:@"success"];
                    if (successValue && ![successValue boolValue]) {
                        if (callbackBlock) {
                            callbackBlock(nil, [NSError errorWithDomain:kKFAPIClientErrorDomain code:105 userInfo:responseDictionary]);
                        }
                        return;
                    }
                    if (callbackBlock) {
                        callbackBlock(responseDictionary, nil);
                        return;
                    }
                } else {
                    if (callbackBlock) {
                        NSError *error = [NSError errorWithDomain:kKFAPIClientErrorDomain code:103 userInfo:@{NSLocalizedDescriptionKey: @"Bad request", @"response": responseObject}];
                        callbackBlock(NO, error);
                    }
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                if (callbackBlock) {
                    callbackBlock(NO, error);
                }
            }];
        }];
    }];
}

- (void) stopStream:(KFStream *)stream callbackBlock:(void (^)(BOOL, NSError *))callbackBlock {
    NSAssert(stream != nil, @"stream cannot be nil!");
    [self betterPostPath:@"/api/stream/stop" parameters:@{@"stream_id": stream.streamID} callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
        if (!callbackBlock) {
            return;
        }
        if (error) {
            callbackBlock(NO, error);
        } else {
            callbackBlock(YES, nil);
        }
    }];
}

- (void) startNewStream:(void (^)(KFStream *, NSError *))endpointCallback {
    NSAssert(endpointCallback != nil, @"endpointCallback should not be nil!");
    [self betterPostPath:@"/api/stream/start" parameters:nil callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
        KFStream *endpoint = nil;
        NSString *streamType = responseDictionary[KFStreamTypeKey];
        if ([streamType isEqualToString:KFS3StreamType]) {
            KFUser *activeUser = [KFUser activeUser];
            endpoint = [[KFS3Stream alloc] initWithUser:activeUser parameters:responseDictionary];
        }
        if (!endpointCallback) {
            return;
        }
        if (endpoint) {
            endpointCallback(endpoint, nil);
        } else {
            endpointCallback(nil, [NSError errorWithDomain:kKFAPIClientErrorDomain code:104 userInfo:@{NSLocalizedDescriptionKey: @"Error parsing response", @"response": responseDictionary}]);
        }
    }];
}

- (void) requestStreamsForUsername:(NSString*)username callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock {
    NSAssert(callbackBlock != nil, @"callbackBlock cannot be nil!");
    NSAssert(username != nil, @"Username should not be nil!");
    NSDictionary *parameters = nil;
    if (username) {
        parameters = @{@"username": username};
    }
    [self betterPostPath:@"/api/search/user" parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
        if (error) {
            callbackBlock(nil, error);
            return;
        }
        DDLogInfo(@"Streams: %@", responseDictionary);
    }];
}

- (void) requestStreamsForLocation:(CLLocation*)location radius:(CLLocationDistance)radius callbackBlock:(void (^)(NSArray *streams, NSError *error))callbackBlock {
    NSAssert(callbackBlock != nil, @"callbackBlock cannot be nil!");
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:4];
    if (location) {
        parameters[@"lat"] = @(location.coordinate.latitude);
        parameters[@"lon"] = @(location.coordinate.longitude);
    }
    if (radius > 0) {
        parameters[@"radius"] = @(radius);
    }
    [self betterPostPath:@"/api/search/location" parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
        if (error) {
            callbackBlock(nil, error);
            return;
        }
        DDLogInfo(@"Fetched streams by location %@", responseDictionary);
    }];
}

@end
