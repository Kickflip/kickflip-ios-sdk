//
//  AVEncoder.m
//  Encoder Demo
//
//  Created by Geraint Davies on 14/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "AVEncoder.h"
#import "NALUnit.h"
#import "LiveEncoder.h"

@implementation EncodedDataWrapper
- (id)initWithData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame {
    if (self = [super init]) {
        _data = data;
        _isKeyFrame = isKeyFrame;
    }
    return self;
}
@end


static void * AVEncoderContext = &AVEncoderContext;

@interface AVEncoder () <LiveEncoderDelegate>

{
    int _height;
    int _width;

    // array of NSData comprising a single frame. each data is one nalu with no start code
    NSMutableArray* _pendingNALU;
    
    // FIFO for frame times
    NSMutableArray* _times;
    
    encoder_handler_t _outputBlock;
    param_handler_t _paramsBlock;
    
    // estimate bitrate over first second
    int _bitspersecond;
    CMTimeValue _firstpts;
}

@property (nonatomic, strong) LiveEncoder *encoder;
@property (atomic) BOOL bitrateChanged;
@property (nonatomic, strong) NSMutableData *dataBuffer;
@property (nonatomic) NSInteger dataReadOffset;
@end

@implementation AVEncoder

@synthesize bitspersecond = _bitspersecond;

- (void)dealloc {
    @try {
        [self removeObserver:self forKeyPath:NSStringFromSelector(@selector(bitrate))];
    } @catch(id anException) {
        // no op
    }
}

+ (AVEncoder*) encoderForHeight:(int) height andWidth:(int) width bitrate:(int)bitrate
{
    AVEncoder* enc = [AVEncoder alloc];
    [enc initForHeight:height andWidth:width bitrate:bitrate];
    return enc;
}

- (void) initForHeight:(int)height andWidth:(int)width bitrate:(int)bitrate
{
    _height = height;
    _width = width;
    _bitrate = bitrate;
    _times = [NSMutableArray arrayWithCapacity:10];
    self.encoder = [[LiveEncoder alloc] initWithHeight:height width:width bitrate:bitrate];
    self.encoder.delegate = self;
    [self addObserver:self forKeyPath:NSStringFromSelector(@selector(bitrate)) options:0 context:AVEncoderContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if (context == AVEncoderContext && [keyPath isEqualToString:NSStringFromSelector(@selector(bitrate))]) {
        self.bitrateChanged = YES;
    }
}

- (void) encodeWithBlock:(encoder_handler_t) block onParams: (param_handler_t) paramsHandler
{
    _outputBlock = block;
    _paramsBlock = paramsHandler;
    _pendingNALU = nil;
    _firstpts = -1;
    _bitspersecond = 0;
}

- (void) encodeFrame:(CMSampleBufferRef) sampleBuffer
{
    CMTime prestime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    NSNumber* pts = [NSNumber numberWithLongLong:prestime.value];
    @synchronized(_times)
    {
        [_times addObject:pts];
    }
    
    [self.encoder encodeSampleBuffer:sampleBuffer];
}

- (void)encoder:(LiveEncoder*)encoder didEncodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {

    NSMutableData *elementaryStream = [NSMutableData data];
    
    // Find out if the sample buffer contains an I-Frame.
    // If so we will write the SPS and PPS NAL units to the elementary stream.
    BOOL isIFrame = NO;
    CFArrayRef attachmentsArray = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, 0);
    if (CFArrayGetCount(attachmentsArray)) {
        CFBooleanRef notSync;
        CFDictionaryRef dict = (CFDictionaryRef)CFArrayGetValueAtIndex(attachmentsArray, 0);
        BOOL keyExists = CFDictionaryGetValueIfPresent(dict,
                                                       kCMSampleAttachmentKey_NotSync,
                                                       (const void **)&notSync);
        // An I-Frame is a sync frame
        isIFrame = !keyExists || !CFBooleanGetValue(notSync);
    }
    
    // This is the start code that we will write to
    // the elementary stream before every NAL unit
    static const size_t startCodeLength = 4;
    static const uint8_t startCode[] = {0x00, 0x00, 0x00, 0x01};
    
    // Write the SPS and PPS NAL units to the elementary stream before every I-Frame
    if (isIFrame) {
        CMFormatDescriptionRef description = CMSampleBufferGetFormatDescription(sampleBuffer);
        
        // Find out how many parameter sets there are
        size_t numberOfParameterSets;
        CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                           0, NULL, NULL,
                                                           &numberOfParameterSets,
                                                           NULL);
        
        // Write each parameter set to the elementary stream
        for (int i = 0; i < numberOfParameterSets; i++) {
            const uint8_t *parameterSetPointer;
            size_t parameterSetLength;
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description,
                                                               i,
                                                               &parameterSetPointer,
                                                               &parameterSetLength,
                                                               NULL, NULL);
            
            // Write the parameter set to the elementary stream
            [elementaryStream appendBytes:startCode length:startCodeLength];
            [elementaryStream appendBytes:parameterSetPointer length:parameterSetLength];
        }
    }
    
    // Get a pointer to the raw AVCC NAL unit data in the sample buffer
    size_t blockBufferLength;
    uint8_t *bufferDataPointer = NULL;
    CMBlockBufferGetDataPointer(CMSampleBufferGetDataBuffer(sampleBuffer),
                                0,
                                NULL,
                                &blockBufferLength,
                                (char **)&bufferDataPointer);
    
    // Loop through all the NAL units in the block buffer
    // and write them to the elementary stream with
    // start codes instead of AVCC length headers
    size_t bufferOffset = 0;
    static const int AVCCHeaderLength = 4;
    while (bufferOffset < blockBufferLength - AVCCHeaderLength) {
        // Read the NAL unit length
        uint32_t NALUnitLength = 0;
        memcpy(&NALUnitLength, bufferDataPointer + bufferOffset, AVCCHeaderLength);
        // Convert the length value from Big-endian to Little-endian
        NALUnitLength = CFSwapInt32BigToHost(NALUnitLength);
        // Write start code to the elementary stream
        [elementaryStream appendBytes:startCode length:startCodeLength];
        // Write the NAL unit without the AVCC length header to the elementary stream
        [elementaryStream appendBytes:bufferDataPointer + bufferOffset + AVCCHeaderLength
                               length:NALUnitLength];
        // Move to the next NAL unit in the block buffer
        bufferOffset += AVCCHeaderLength + NALUnitLength;
    }
    
    [self onEncodedFrame:elementaryStream isKeyFrame:isIFrame];
}

- (void) onEncodedFrame:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    CMTimeValue pts = 0;
    @synchronized(_times)
    {
        if ([_times count] > 0)
        {
            NSNumber *time = _times[0];
            pts = [time longLongValue];
            [_times removeObjectAtIndex:0];
            if (_firstpts < 0)
            {
                _firstpts = pts;
            }
            if ((pts - _firstpts) < 1)
            {
                int bytes = 0;
                for (NSData* data in _pendingNALU)
                {
                    bytes += [data length];
                }
                _bitspersecond += (bytes * 8);
            }
        }
        else
        {
            //NSLog(@"no pts for buffer");
        }
    }
    if (_outputBlock != nil)
    {
        EncodedDataWrapper *wrapper = [[EncodedDataWrapper alloc] initWithData:data isKeyFrame:isKeyFrame];
        _outputBlock(wrapper, pts);
    }
}

- (void) shutdown
{
    [self.encoder finish];
    self.encoder = nil;
}

@end
