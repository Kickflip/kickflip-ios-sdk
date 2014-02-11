//
//  AACEncoder.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/18/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "KFEncoder.h"

@interface KFAACEncoder : KFEncoder <KFSampleBufferEncoder>

@property (nonatomic) BOOL addADTSHeader;

@end
