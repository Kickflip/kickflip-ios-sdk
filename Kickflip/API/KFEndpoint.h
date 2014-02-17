//
//  KFEndpoint.h
//  Kickflip
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@class KFUser;

extern NSString * const KFEndpointStreamTypeKey;

@interface KFEndpoint : NSObject

@property (nonatomic, strong) KFUser *user;
@property (nonatomic, strong) NSString *streamType;
@property (nonatomic, strong) NSString *streamID;
@property (nonatomic, strong) NSURL *uploadURL;
@property (nonatomic, strong) NSURL *streamURL;
@property (nonatomic, strong) NSURL *kickflipURL;
@property (nonatomic, strong) NSURL *chatURL;

- (instancetype) initWithUser:(KFUser*)user parameters:(NSDictionary*)parameters;

@end
