//
//  HLSWriter.h
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/16/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HLSWriter : NSObject

@property (nonatomic, strong) NSString *uuid;
@property (nonatomic) dispatch_queue_t conversionQueue;
@property (nonatomic, strong, readonly) NSString *directoryPath;

- (id) initWithDirectoryPath:(NSString*)directoryPath;

- (void) addVideoStreamWithWidth:(int)width height:(int)height;
- (void) addAudioStreamWithSampleRate:(int)sampleRate;

- (BOOL) prepareForWriting:(NSError**)error;

- (void) processEncodedData:(NSData*)data presentationTimestamp:(double)pts streamIndex:(NSUInteger)streamIndex;

- (BOOL) finishWriting:(NSError**)error;

@end
