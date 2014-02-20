//
//  KFStream.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFStream.h"

NSString * const KFStreamTypeKey = @"stream_type";
static NSString * const KFStreamIDKey = @"stream_id";

static NSString * const KFStreamUploadURLKey = @"upload_url";
static NSString * const KFStreamURLKey = @"stream_url";
static NSString * const KFStreamKickflipURLKey = @"kickflip_url";
static NSString * const KFStreamChatURLKey = @"chat_url";
static NSString * const KFStreamStateKey = @"KFStreamStateKey";

@implementation KFStream

- (instancetype) initWithUser:(KFUser *)user parameters:(NSDictionary *)parameters {
    if (self = [super init]) {
        self.user = user;
        [self parseParameters:parameters];
    }
    return self;
}

- (void) parseParameters:(NSDictionary*)parameters {
    self.streamType = parameters[KFStreamTypeKey];
    self.streamID = parameters[KFStreamIDKey];
    self.uploadURL = [NSURL URLWithString:parameters[KFStreamUploadURLKey]];
    self.streamURL = [NSURL URLWithString:parameters[KFStreamURLKey]];
    self.kickflipURL = [NSURL URLWithString:parameters[KFStreamKickflipURLKey]];
    self.chatURL = [NSURL URLWithString:parameters[KFStreamChatURLKey]];
    NSNumber *streamStateNumber = parameters[KFStreamStateKey];
    self.streamState = streamStateNumber.intValue;
}

- (NSDictionary*) dictionaryRepresentation {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if (self.streamType) {
        [dict setObject:self.streamType forKey:KFStreamTypeKey];
    }
    if (self.streamID) {
        [dict setObject:self.streamID forKey:KFStreamIDKey];
    }
    if (self.streamURL) {
        [dict setObject:self.streamURL forKey:KFStreamURLKey];
    }
    if (self.kickflipURL) {
        [dict setObject:self.kickflipURL forKey:KFStreamKickflipURLKey];
    }
    if (self.chatURL) {
        [dict setObject:self.chatURL forKey:KFStreamChatURLKey];
    }
    [dict setObject:@(self.streamState) forKey:KFStreamStateKey];
    return dict;
}

- (NSString*) description {
    return [self dictionaryRepresentation].description;
}

@end
