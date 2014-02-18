//
//  KFEndpoint.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFEndpoint.h"

NSString * const KFEndpointStreamTypeKey = @"stream_type";
static NSString * const KFEndpointStreamIDKey = @"streamID";

static NSString * const KFEndpointUploadURLKey = @"upload_url";
static NSString * const KFEndpointStreamURLKey = @"stream_url";
static NSString * const KFEndpointKickflipURLKey = @"kickflip_url";
static NSString * const KFEndpointChatURLKey = @"chat_url";

@implementation KFEndpoint

- (instancetype) initWithUser:(KFUser *)user parameters:(NSDictionary *)parameters {
    if (self = [super init]) {
        self.user = user;
        [self parseParameters:parameters];
    }
    return self;
}

- (void) parseParameters:(NSDictionary*)parameters {
    self.streamType = parameters[KFEndpointStreamTypeKey];
    self.streamID = parameters[KFEndpointStreamIDKey];
    self.uploadURL = [NSURL URLWithString:parameters[KFEndpointUploadURLKey]];
    self.streamURL = [NSURL URLWithString:parameters[KFEndpointStreamURLKey]];
    self.kickflipURL = [NSURL URLWithString:parameters[KFEndpointKickflipURLKey]];
    self.chatURL = [NSURL URLWithString:parameters[KFEndpointChatURLKey]];
}

- (NSDictionary*) dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.streamType) {
        [dict setObject:self.streamType forKey:KFEndpointStreamTypeKey];
    }
    if (self.streamID) {
        [dict setObject:self.streamID forKey:KFEndpointStreamIDKey];
    }
    if (self.streamURL) {
        [dict setObject:self.streamURL forKey:KFEndpointStreamURLKey];
    }
    if (self.kickflipURL) {
        [dict setObject:self.kickflipURL forKey:KFEndpointKickflipURLKey];
    }
    if (self.chatURL) {
        [dict setObject:self.chatURL forKey:KFEndpointChatURLKey];
    }
    return dict;
}

- (NSString*) description {
    return [self dictionaryRepresentation].description;
}

@end
