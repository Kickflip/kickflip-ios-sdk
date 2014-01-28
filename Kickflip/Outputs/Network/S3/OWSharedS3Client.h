//
//  OWSharedS3Client.h
//  LiveStreamer
//
//  Created by Christopher Ballinger on 10/4/13.
//  Copyright (c) 2013 OpenWatch, Inc. All rights reserved.
//

#import "OWS3Client.h"

@interface OWSharedS3Client : OWS3Client

+ (OWSharedS3Client*) sharedClient;

@end
