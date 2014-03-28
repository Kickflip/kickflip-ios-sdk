//
//  KFHLSWriter.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 12/16/13.
//  Copyright (c) 2013 Christopher Ballinger. All rights reserved.
//

#import "KFHLSWriter.h"
#import "FFOutputFile.h"
#import "FFmpegWrapper.h"
#import "libavformat/avformat.h"
#import "libavcodec/avcodec.h"
#import "libavutil/opt.h"
#import "librtmp/log.h"
#import "KFLog.h"

@interface KFHLSWriter()
@property (nonatomic, strong) FFOutputFile *outputFile;
@property (nonatomic, strong) FFOutputStream *videoStream;
@property (nonatomic, strong) FFOutputStream *audioStream;
@property (nonatomic) AVPacket *packet;
@property (nonatomic) AVRational videoTimeBase;
@property (nonatomic) AVRational audioTimeBase;
@property (nonatomic) NSUInteger segmentDurationSeconds;
@end

@implementation KFHLSWriter

- (id) initWithDirectoryPath:(NSString *)directoryPath {
    if (self = [super init]) {
        av_register_all();
        avformat_network_init();
        avcodec_register_all();
        
#if DEBUG
        av_log_set_level(AV_LOG_VERBOSE);
        RTMP_LogSetLevel(RTMP_LOGALL);
#else
        av_log_set_level(AV_LOG_QUIET);
        RTMP_LogSetLevel(RTMP_LOGCRIT);
#endif
        
        _directoryPath = directoryPath;
        _packet = av_malloc(sizeof(AVPacket));
        _videoTimeBase.num = 1;
        _videoTimeBase.den = 1000000000;
        _audioTimeBase.num = 1;
        _audioTimeBase.den = 1000000000;
        _segmentDurationSeconds = 10;
        [self setupOutputFile];
        _conversionQueue = dispatch_queue_create("HLS Write queue", DISPATCH_QUEUE_SERIAL);
        _uuid = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (void) setupOutputFile {
    NSString *outputPath = [_directoryPath stringByAppendingPathComponent:@"index.m3u8"];
    
    _outputFile = [[FFOutputFile alloc] initWithPath:outputPath options:@{kFFmpegOutputFormatKey: @"hls"}];
    
    FFBitstreamFilter *bitstreamFilter = [[FFBitstreamFilter alloc] initWithFilterName:@"h264_mp4toannexb"];
    [_outputFile addBitstreamFilter:bitstreamFilter];
}

- (void) addVideoStreamWithWidth:(int)width height:(int)height {
    _videoStream = [[FFOutputStream alloc] initWithOutputFile:_outputFile outputCodec:@"h264"];
    [_videoStream setupVideoContextWithWidth:width height:height];
    av_opt_set_int(_outputFile.formatContext->priv_data, "hls_time", _segmentDurationSeconds, 0);
}

- (void) addAudioStreamWithSampleRate:(int)sampleRate {
    _audioStream = [[FFOutputStream alloc] initWithOutputFile:_outputFile outputCodec:@"aac"];
    [_audioStream setupAudioContextWithSampleRate:sampleRate];
}

- (BOOL) prepareForWriting:(NSError *__autoreleasing *)error {
    // Open the output file for writing and write header
    if (![_outputFile openFileForWritingWithError:error]) {
        return NO;
    }
    if (![_outputFile writeHeaderWithError:error]) {
        return NO;
    }
    return YES;
}


- (void) processEncodedData:(NSData*)data presentationTimestamp:(CMTime)pts streamIndex:(NSUInteger)streamIndex isKeyFrame:(BOOL)isKeyFrame {
    if (data.length == 0) {
        return;
    }
    dispatch_async(_conversionQueue, ^{
        av_init_packet(_packet);
        
        uint64_t originalPTS = pts.value;
        
        // This lets the muxer know about H264 keyframes
        if (streamIndex == 0 && isKeyFrame) { // this is hardcoded to video right now
            _packet->flags |= AV_PKT_FLAG_KEY;
        }
        
        _packet->data = (uint8_t*)data.bytes;
        _packet->size = (int)data.length;
        _packet->stream_index = streamIndex;
        uint64_t scaledPTS = av_rescale_q(originalPTS, _videoTimeBase, _outputFile.formatContext->streams[_packet->stream_index]->time_base);
        //DDLogInfo(@"*** Scaled PTS: %lld", scaledPTS);
        
        _packet->pts = scaledPTS;
        _packet->dts = scaledPTS;
        NSError *error = nil;
        [_outputFile writePacket:_packet error:&error];
        if (error) {
            DDLogError(@"Error writing packet at streamIndex %d and PTS %lld: %@", streamIndex, originalPTS, error.description);
        } else {
            //DDLogVerbose(@"Wrote packet of length %d at streamIndex %d and \t oPTS %lld \t scaledPTS %lld", data.length, streamIndex, originalPTS, scaledPTS);
        }
    });
}

- (BOOL) finishWriting:(NSError *__autoreleasing *)error {
    return [_outputFile writeTrailerWithError:error];
}

@end
