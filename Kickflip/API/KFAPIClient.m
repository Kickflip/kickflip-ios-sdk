//
//  KFAPIClient.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFAPIClient.h"
#import "AFOAuth2Manager.h"
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
    NSURL *url = [NSURL URLWithString:@"https://kickflip.io/api/1.2"];
    if (self = [super initWithBaseURL:url]) {
        [self checkOAuthCredentialsWithCallback:nil];
    }
    return self;
}

- (void) checkOAuthCredentialsWithCallback:(void (^)(BOOL success, NSError * error))callback {
    if ([self.requestSerializer valueForHTTPHeaderField:@"Authorization"] != nil) {
        if (callback) {
            callback(YES, nil);
        }
        return;
    }
    NSURL *url = self.baseURL;
    NSString *apiKey = [Kickflip apiKey];
    NSString *apiSecret = [Kickflip apiSecret];
    NSAssert(apiKey != nil && apiSecret != nil, @"Missing API key and secret. Call [Kickflip setupWithAPIKey:secret:] with your credentials obtained from kickflip.io");

    AFOAuth2Manager *oauthClient = [[AFOAuth2Manager alloc] initWithBaseURL:url clientID:apiKey secret:apiSecret];
    
    AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:apiKey];
    if (credential && !credential.isExpired) {
        [self setAuthorizationHeaderWithCredential:credential];
        if (callback) {
            callback(YES, nil);
        }
        return;
    }

    [oauthClient authenticateUsingOAuthWithURLString:@"/o/token/" parameters:@{@"grant_type": kAFOAuthClientCredentialsGrantType} success:^(AFOAuthCredential *credential) {
        [AFOAuthCredential storeCredential:credential withIdentifier:apiKey];
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
    [self.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", credential.accessToken] forHTTPHeaderField:@"Authorization"];
}

- (NSString*) serializeExtraUserInfo:(NSDictionary*)extraInfo {
    if (!extraInfo) {
        return nil;
    }
    if ([NSJSONSerialization isValidJSONObject:extraInfo]) {
        NSData *data = [NSJSONSerialization dataWithJSONObject:extraInfo options:NSJSONWritingPrettyPrinted error:nil];
        NSString *extraInfo = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        return extraInfo;
    }
    return nil;
}

- (void) requestNewActiveUserWithUsername:(NSString *)username password:(NSString *)password email:(NSString *)email displayName:(NSString *)displayName extraInfo:(NSDictionary *)extraInfo callbackBlock:(void (^)(KFUser *, NSError *))callbackBlock {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:5];
    if (username) {
        [parameters setObject:username forKey:@"username"];
    }
    if (password) {
        [parameters setObject:password forKey:@"password"];
    }
    if (email) {
        [parameters setObject:email forKey:@"email"];
    }
    if (displayName) {
        [parameters setObject:displayName forKey:@"display_name"];
    }
    if (extraInfo) {
        NSString *extraInfoString = [self serializeExtraUserInfo:extraInfo];
        if (extraInfo) {
            [parameters setObject:extraInfoString forKey:@"extra_info"];
        }
    }
    [self checkOAuthCredentialsWithCallback:^(BOOL success, NSError *error) {
        if (!success) {
            if (callbackBlock) {
                callbackBlock(nil, error);
            }
            return;
        }
        [self parsePostPath:@"user/new" parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
            if (error) {
                if (callbackBlock) {
                    callbackBlock(nil, error);
                }
                return;
            }
            error = nil;
            
            KFUser *user = [MTLJSONAdapter modelOfClass:[KFUser class] fromJSONDictionary:responseDictionary error:&error];
            if (error) {
                if (callbackBlock) {
                    callbackBlock(nil, error);
                }
                return;
            }
            [KFUser setActiveUser:user];
            if (callbackBlock) {
                callbackBlock(user, nil);
            }
        }];
    }];
}

- (void) requestUserInfoForUsername:(NSString*)username callbackBlock:(void (^)(KFUser *existingUser, NSError *error))callbackBlock {
    [self checkOAuthCredentialsWithCallback:^(BOOL success, NSError *error) {
        if (!success) {
            if (callbackBlock) {
                callbackBlock(nil, error);
            }
            return;
        }
        [self parsePostPath:@"user/info" parameters:@{@"username": username} callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
            if (error) {
                if (callbackBlock) {
                    callbackBlock(nil, error);
                }
                return;
            }
            error = nil;
            
            KFUser *user = [MTLJSONAdapter modelOfClass:[KFUser class] fromJSONDictionary:responseDictionary error:&error];
            if (error) {
                if (callbackBlock) {
                    callbackBlock(nil, error);
                }
                return;
            }
            if (callbackBlock) {
                callbackBlock(user, nil);
            }
        }];
    }];
}

- (void) updateMetadataForActiveUserWithNewPassword:(NSString*)newPassword email:(NSString*)email displayName:(NSString*)displayName extraInfo:(NSDictionary*)extraInfo callbackBlock:(void (^)(KFUser *updatedUser, NSError *error))callbackBlock {
    KFUser *user = [KFUser activeUser];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:5];
    [parameters setObject:user.username forKey:@"username"];
    [parameters setObject:user.password forKey:@"password"];
    if (newPassword) {
        [parameters setObject:newPassword forKey:@"new_password"];
    }
    if (email) {
        [parameters setObject:email forKey:@"email"];
    }
    if (displayName) {
        [parameters setObject:displayName forKey:@"display_name"];
    }
    if (extraInfo) {
        NSString *extraInfoString = [self serializeExtraUserInfo:extraInfo];
        if (extraInfo) {
            [parameters setObject:extraInfoString forKey:@"extra_info"];
        }
    }
    [self checkOAuthCredentialsWithCallback:^(BOOL success, NSError *error) {
        if (!success) {
            if (callbackBlock) {
                callbackBlock(nil, error);
            }
            return;
        }
        [self parsePostPath:@"user/change" parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
            if (error) {
                if (callbackBlock) {
                    callbackBlock(nil, error);
                }
                return;
            }
            error = nil;
            
            KFUser *user = [MTLJSONAdapter modelOfClass:[KFUser class] fromJSONDictionary:responseDictionary error:&error];
            if (error) {
                if (callbackBlock) {
                    callbackBlock(nil, error);
                }
                return;
            }
            [KFUser setActiveUser:user];
            if (callbackBlock) {
                callbackBlock(user, nil);
            }
        }];
    }];
}

- (void) loginExistingUserWithUsername:(NSString *)username password:(NSString *)password callbackBlock:(void (^)(KFUser *, NSError *))callbackBlock {
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:2];
    [parameters setObject:username forKey:@"username"];
    [parameters setObject:password forKey:@"password"];
    [self checkOAuthCredentialsWithCallback:^(BOOL success, NSError *error) {
        if (!success) {
            if (callbackBlock) {
                callbackBlock(nil, error);
            }
            return;
        }
        [self parsePostPath:@"user/uuid" parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
            if (error) {
                if (callbackBlock) {
                    callbackBlock(nil, error);
                }
                return;
            }
            error = nil;
            
            KFUser *user = [MTLJSONAdapter modelOfClass:[KFUser class] fromJSONDictionary:responseDictionary error:&error];
            if (error) {
                if (callbackBlock) {
                    callbackBlock(nil, error);
                }
                return;
            }
            user.password = password;
            [KFUser setActiveUser:user];
            if (callbackBlock) {
                callbackBlock(user, nil);
            }
        }];
    }];

}

- (void) requestNewActiveUserWithUsername:(NSString*)username callbackBlock:(void (^)(KFUser *activeUser, NSError *error))callbackBlock {
    [self requestNewActiveUserWithUsername:username password:nil email:nil displayName:nil extraInfo:nil callbackBlock:callbackBlock];
}

- (void) parsePostPath:(NSString*)path parameters:(NSDictionary*)parameters callbackBlock:(void (^)(NSDictionary *responseDictionary, NSError *error))callbackBlock {
    [self POST:path parameters:parameters success:^(NSURLSessionDataTask *task, id responseObject) {
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
                callbackBlock(nil, error);
            }
        }
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        if (callbackBlock) {
            callbackBlock(nil, error);
        }
    }];
}

- (void) parsePostPath:(NSString*)path activeUser:(KFUser*)activeUser parameters:(NSDictionary*)parameters callbackBlock:(void (^)(NSDictionary *responseDictionary, NSError *error))callbackBlock {
    NSMutableDictionary *fullParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    if (!activeUser) {
        if (callbackBlock) {
            callbackBlock(nil, [NSError errorWithDomain:kKFAPIClientErrorDomain code:105 userInfo:@{NSLocalizedDescriptionKey: @"Fetch an active user first"}]);
        }
        return;
    }
    [fullParameters setObject:activeUser.uuid forKey:@"uuid"];
    [self parsePostPath:path parameters:fullParameters callbackBlock:callbackBlock];
}

- (void) betterPostPath:(NSString*)path parameters:(NSDictionary*)parameters callbackBlock:(void (^)(NSDictionary *responseDictionary, NSError *error))callbackBlock {
    [self checkOAuthCredentialsWithCallback:^(BOOL success, NSError *error) {
        if (!success) {
            if (callbackBlock) {
                callbackBlock(nil, error);
            }
            return;
        }
        KFUser *activeUser = [KFUser activeUser];
        if (!activeUser) {
            [self requestNewActiveUserWithUsername:nil callbackBlock:^(KFUser *activeUser, NSError *error) {
                if (!activeUser) {
                    callbackBlock(nil, error);
                }
                [self parsePostPath:path activeUser:activeUser parameters:parameters callbackBlock:callbackBlock];
            }];
            return;
        }
        [self parsePostPath:path activeUser:activeUser parameters:parameters callbackBlock:callbackBlock];
    }];
}

- (void) stopStream:(KFStream *)stream callbackBlock:(void (^)(BOOL, NSError *))callbackBlock {
    NSAssert(stream != nil, @"stream cannot be nil!");
    [self betterPostPath:@"stream/stop" parameters:@{@"stream_id": stream.streamID} callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
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

- (void) startStreamWithParameters:(NSDictionary*)parameters callbackBlock:(void (^)(KFStream *, NSError *))endpointCallback {
    NSAssert(endpointCallback != nil, @"endpointCallback should not be nil!");
    [self betterPostPath:@"stream/start" parameters:nil callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
        if (error) {
            endpointCallback(nil, error);
            return;
        }
        KFStream *endpoint = nil;
        NSString *streamType = responseDictionary[KFStreamTypeKey];
        if ([streamType isEqualToString:KFS3StreamType]) {
            KFUser *activeUser = [KFUser activeUser];
            endpoint = [MTLJSONAdapter modelOfClass:[KFS3Stream class] fromJSONDictionary:responseDictionary error:&error];
            endpoint.username = activeUser.username;
        }
        if (error) {
            endpointCallback(nil, error);
            return;
        }
        if (endpoint) {
            endpointCallback(endpoint, nil);
        } else {
            endpointCallback(nil, [NSError errorWithDomain:kKFAPIClientErrorDomain code:104 userInfo:@{NSLocalizedDescriptionKey: @"Error parsing response", @"response": responseDictionary}]);
        }
    }];
}

- (void) startNewStream:(void (^)(KFStream *, NSError *))endpointCallback {
    [self startStreamWithParameters:nil callbackBlock:endpointCallback];
}

- (void) startNewPrivateStream:(void (^)(KFStream *, NSError *))endpointCallback {
    [self startStreamWithParameters:@{@"private": @YES} callbackBlock:endpointCallback];
}

- (void) requestStreamsForUsername:(NSString*)username pageNumber:(NSUInteger)pageNumber itemsPerPage:(NSUInteger)itemsPerPage callbackBlock:(void (^)(NSArray *streams, KFPaginationInfo *paginationInfo, NSError *error))callbackBlock {
    NSAssert(callbackBlock != nil, @"callbackBlock cannot be nil!");
    NSAssert(username != nil, @"Username should not be nil!");
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (username) {
        [parameters setObject:username forKey:@"username"];
    }
    [self setPaginationForParameters:parameters pageNumber:pageNumber itemsPerPage:itemsPerPage];

    [self betterPostPath:@"search/user" parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
        if (error) {
            callbackBlock(nil, nil, error);
            return;
        }
        NSArray *streamDictionaries = [responseDictionary objectForKey:@"streams"];
        KFPaginationInfo *paginationInfo = [self paginationInfoFromResponseDictionary:responseDictionary error:&error];
        if (error) {
            callbackBlock(nil, nil, error);
            return;
        }
        [self serializeObjects:streamDictionaries class:[KFStream class] callbackBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                callbackBlock(nil, nil, error);
            } else {
                callbackBlock(objects, paginationInfo, nil);
            }
        }];
    }];
}

- (void) requestStreamsForLocation:(CLLocation*)location radius:(CLLocationDistance)radius pageNumber:(NSUInteger)pageNumber itemsPerPage:(NSUInteger)itemsPerPage callbackBlock:(void (^)(NSArray *streams, KFPaginationInfo *paginationInfo, NSError *error))callbackBlock {
    NSAssert(callbackBlock != nil, @"callbackBlock cannot be nil!");
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithCapacity:4];
    if (location) {
        parameters[@"lat"] = @(location.coordinate.latitude);
        parameters[@"lon"] = @(location.coordinate.longitude);
    }
    if (radius > 0) {
        parameters[@"radius"] = @(radius);
    }
    [self setPaginationForParameters:parameters pageNumber:pageNumber itemsPerPage:itemsPerPage];

    [self betterPostPath:@"search/location" parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
        if (error) {
            callbackBlock(nil, nil, error);
            return;
        }
        KFPaginationInfo *paginationInfo = [self paginationInfoFromResponseDictionary:responseDictionary error:&error];
        if (error) {
            callbackBlock(nil, nil, error);
            return;
        }
        NSArray *streamDictionaries = [responseDictionary objectForKey:@"streams"];
        [self serializeObjects:streamDictionaries class:[KFStream class] callbackBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                callbackBlock(nil, nil, error);
            } else {
                callbackBlock(objects, paginationInfo, nil);
            }
        }];
    }];
}


- (KFPaginationInfo*) paginationInfoFromResponseDictionary:(NSDictionary*)dictionary error:(NSError**)error {
    KFPaginationInfo *paginationInfo = [MTLJSONAdapter modelOfClass:[KFPaginationInfo class] fromJSONDictionary:dictionary error:error];
    return paginationInfo;
}


- (void) setPaginationForParameters:(NSMutableDictionary*)parameters pageNumber:(NSUInteger)pageNumber itemsPerPage:(NSUInteger)itemsPerPage {
    NSAssert(pageNumber != 0, @"The first page starts at 1, not 0!");
    [parameters setObject:@(pageNumber) forKey:@"page"];
    [parameters setObject:@(itemsPerPage) forKey:@"results_per_page"];
}

/**
 * Returns all the streams with metadata containing keyword
 */
- (void) requestStreamsByKeyword:(NSString*)keyword pageNumber:(NSUInteger)pageNumber itemsPerPage:(NSUInteger)itemsPerPage callbackBlock:(void (^)(NSArray *streams, KFPaginationInfo *paginationInfo, NSError *error))callbackBlock {
    NSAssert(callbackBlock != nil, @"callbackBlock cannot be nil!");
    NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
    if (keyword) {
        [parameters setObject:keyword forKey:@"keyword"];
    }
    [self setPaginationForParameters:parameters pageNumber:pageNumber itemsPerPage:itemsPerPage];
    
    [self betterPostPath:@"search" parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
        if (error) {
            callbackBlock(nil, nil, error);
            return;
        }
        KFPaginationInfo *paginationInfo = [self paginationInfoFromResponseDictionary:responseDictionary error:&error];
        if (error) {
            callbackBlock(nil, nil, error);
            return;
        }
        NSArray *streamDictionaries = [responseDictionary objectForKey:@"streams"];
        [self serializeObjects:streamDictionaries class:[KFStream class] callbackBlock:^(NSArray *objects, NSError *error) {
            if (error) {
                callbackBlock(nil, nil, error);
            } else {
                callbackBlock(objects, paginationInfo, nil);
            }
        }];
    }];
}

- (void) serializeObjects:(NSArray*)objects class:(Class)class callbackBlock:(void (^)(NSArray *objects, NSError *error))callbackBlock {
    NSAssert(objects != nil, @"objects shouldnt be nil");
    NSAssert(callbackBlock != nil, @"callbackBlock shouldnt be nil");
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *array = [NSMutableArray arrayWithCapacity:objects.count];
        for (NSDictionary *object in objects) {
            NSError *error = nil;
            id model = [MTLJSONAdapter modelOfClass:class fromJSONDictionary:object error:&error];
            if (error) {
                callbackBlock(nil, error);
                return;
            }
            [array addObject:model];
        }
        callbackBlock(array, nil);
    });
}

- (void) requestAllStreamsWithPageNumber:(NSUInteger)pageNumber itemsPerPage:(NSUInteger)itemsPerPage callbackBlock:(void (^)(NSArray *streams, KFPaginationInfo *paginationInfo, NSError *error))callbackBlock {
    [self requestStreamsByKeyword:nil pageNumber:pageNumber itemsPerPage:itemsPerPage  callbackBlock:callbackBlock];
}

- (void) updateMetadataForStream:(KFStream *)stream callbackBlock:(void (^)(KFStream* updatedStream, NSError *))callbackBlock {
    NSDictionary *parameters = [MTLJSONAdapter JSONDictionaryFromModel:stream];
    /*
    NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
    DDLogInfo(@"updateMetadata outgoing jsonString: %@", jsonString);
    */
    [self betterPostPath:@"stream/change" parameters:parameters callbackBlock:^(NSDictionary *responseDictionary, NSError *error) {
        if (!callbackBlock) {
            return;
        }
        if (error) {
            callbackBlock(nil, error);
            return;
        }
        KFStream *updatedStream = [MTLJSONAdapter modelOfClass:[KFStream class] fromJSONDictionary:responseDictionary error:&error];
        if (error) {
            callbackBlock(nil, error);
            return;
        }
        callbackBlock(updatedStream, nil);
    }];
}

@end
