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

static void * AVEncoderContext = &AVEncoderContext;

static unsigned int to_host(unsigned char* p)
{
    return (p[0] << 24) + (p[1] << 16) + (p[2] << 8) + p[3];
}

#define OUTPUT_FILE_SWITCH_POINT (50 * 1024 * 1024)  // 50 MB switch point
#define MAX_FILENAME_INDEX  5                       // filenames "capture1.mp4" wraps at capture5.mp4


@interface AVEncoder () <LiveEncoderDelegate>

{
    // initial writer, used to obtain SPS/PPS from header
    VideoEncoder* _headerWriter;
    
    // main encoder/writer
    VideoEncoder* _writer;
    
    // writer output file (input to our extractor) and monitoring
    NSFileHandle* _inputFile;
    dispatch_queue_t _readQueue;
    dispatch_source_t _readSource;
    
    // index of current file name
    BOOL _swapping;
    int _currentFile;
    int _height;
    int _width;
    
    // param set data
    NSData* _avcC;
    int _lengthSize;
    
    // location of mdat
    BOOL _foundMDAT;
    uint64_t _posMDAT;
    int _bytesToNextAtom;
    BOOL _needParams;
    
    // tracking if NALU is next frame
    int _prev_nal_idc;
    int _prev_nal_type;
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

- (NSString*) makeFilename
{
    NSString* filename = [NSString stringWithFormat:@"capture%d.mp4", _currentFile];
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    return path;
}

- (void) initForHeight:(int)height andWidth:(int)width bitrate:(int)bitrate
{
    _height = height;
    _width = width;
    _bitrate = bitrate;
    NSString* path = [NSTemporaryDirectory() stringByAppendingPathComponent:@"params.mp4"];
    _headerWriter = [VideoEncoder encoderForPath:path Height:height andWidth:width bitrate:self.bitrate];
    _times = [NSMutableArray arrayWithCapacity:10];
    
    // swap between 3 filenames
    _currentFile = 1;
    _writer = [VideoEncoder encoderForPath:[self makeFilename] Height:height andWidth:width bitrate:self.bitrate];
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
    _needParams = YES;
    _pendingNALU = nil;
    _firstpts = -1;
    _bitspersecond = 0;
}

- (BOOL) parseParams:(NSString*) path
{
    NSFileHandle* file = [NSFileHandle fileHandleForReadingAtPath:path];
    struct stat s;
    fstat([file fileDescriptor], &s);
    MP4Atom* movie = [MP4Atom atomAt:0 size:s.st_size type:(OSType)('file') inFile:file];
    MP4Atom* moov = [movie childOfType:(OSType)('moov') startAt:0];
    MP4Atom* trak = nil;
    if (moov != nil)
    {
        for (;;)
        {
            trak = [moov nextChild];
            if (trak == nil)
            {
                break;
            }
            
            if (trak.type == (OSType)('trak'))
            {
                MP4Atom* tkhd = [trak childOfType:(OSType)('tkhd') startAt:0];
                NSData* verflags = [tkhd readAt:0 size:4];
                unsigned char* p = (unsigned char*)[verflags bytes];
                if (p[3] & 1)
                {
                    break;
                }
                else
                {
                    tkhd = nil;
                }
            }
        }
    }
    MP4Atom* stsd = nil;
    if (trak != nil)
    {
        MP4Atom* media = [trak childOfType:(OSType)('mdia') startAt:0];
        if (media != nil)
        {
            MP4Atom* minf = [media childOfType:(OSType)('minf') startAt:0];
            if (minf != nil)
            {
                MP4Atom* stbl = [minf childOfType:(OSType)('stbl') startAt:0];
                if (stbl != nil)
                {
                    stsd = [stbl childOfType:(OSType)('stsd') startAt:0];
                }
            }
        }
    }
    if (stsd != nil)
    {
        MP4Atom* avc1 = [stsd childOfType:(OSType)('avc1') startAt:8];
        if (avc1 != nil)
        {
            MP4Atom* esd = [avc1 childOfType:(OSType)('avcC') startAt:78];
            if (esd != nil)
            {
                // this is the avcC record that we are looking for
                _avcC = [esd readAt:0 size:esd.length];
                if (_avcC != nil)
                {
                    // extract size of length field
                    unsigned char* p = (unsigned char*)[_avcC bytes];
                    _lengthSize = (p[4] & 3) + 1;
                    return YES;
                }
            }
        }
    }
    return NO;
}

- (void) onParamsCompletion
{
    // the initial one-frame-only file has been completed
    // Extract the avcC structure and then start monitoring the
    // main file to extract video from the mdat chunk.
    if ([self parseParams:_headerWriter.path])
    {
        if (_paramsBlock)
        {
            _paramsBlock(_avcC);
        }
        _headerWriter = nil;
        _swapping = NO;
        _inputFile = [NSFileHandle fileHandleForReadingAtPath:_writer.path];
        _readQueue = dispatch_queue_create("uk.co.gdcl.avencoder.read", DISPATCH_QUEUE_SERIAL);
        
        _readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, [_inputFile fileDescriptor], 0, _readQueue);
        dispatch_source_set_event_handler(_readSource, ^{
            [self onFileUpdate];
        });
        dispatch_resume(_readSource);
    }
}

- (void) encodeFrame:(CMSampleBufferRef) sampleBuffer
{
    @synchronized(self)
    {
        if (NO) //_needParams)
        {
            // the avcC record is needed for decoding and it's not written to the file until
            // completion. We get round that by writing the first frame to two files; the first
            // file (containing only one frame) is then finished, so we can extract the avcC record.
            // Only when we've got that do we start reading from the main file.
            _needParams = NO;
            if ([_headerWriter encodeFrame:sampleBuffer])
            {
                [_headerWriter finishWithCompletionHandler:^{
                    [self onParamsCompletion];
                }];
            }
        }
    }
    CMTime prestime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    NSNumber* pts = [NSNumber numberWithLongLong:prestime.value];
    @synchronized(_times)
    {
        NSLog(@"add pts: %ull", pts.longLongValue);
        [_times addObject:pts];
    }
    
    [self.encoder encodeSampleBuffer:sampleBuffer];
    return;
    @synchronized(self)
    {
        // switch output files when we reach a size limit
        // to avoid runaway storage use.
        if (!_swapping)
        {
            struct stat st;
            fstat([_inputFile fileDescriptor], &st);
            if (st.st_size > OUTPUT_FILE_SWITCH_POINT || self.bitrateChanged)
            {
                self.bitrateChanged = NO;
                _swapping = YES;
                VideoEncoder* oldVideo = _writer;
                
                // construct a new writer to the next filename
                if (++_currentFile > MAX_FILENAME_INDEX)
                {
                    _currentFile = 1;
                }
//                NSLog(@"Swap to file %d", _currentFile);
                _writer = [VideoEncoder encoderForPath:[self makeFilename] Height:_height andWidth:_width bitrate:self.bitrate];
                
                // to do this seamlessly requires a few steps in the right order
                // first, suspend the read source
                dispatch_source_cancel(_readSource);
                // execute the next step as a block on the same queue, to be sure the suspend is done
                dispatch_async(_readQueue, ^{
                    // finish the file, writing moov, before reading any more from the file
                    // since we don't yet know where the mdat ends
                    _readSource = nil;
                    [oldVideo finishWithCompletionHandler:^{
                        [self swapFiles:oldVideo.path];
                    }];
                });
            }
        }
        [_writer encodeFrame:sampleBuffer];
    }
}

- (void) swapFiles:(NSString*) oldPath
{
    // TEL
    // Sometimes _inputFile is nil and things crash. These bits are beyond my capabilities...
    if (_inputFile) {
        // save current position
        uint64_t pos = [_inputFile offsetInFile];
        
        // re-read mdat length
        [_inputFile seekToFileOffset:_posMDAT];
        NSData* hdr = [_inputFile readDataOfLength:4];
        unsigned char* p = (unsigned char*) [hdr bytes];
        int lenMDAT = to_host(p);

        // extract nalus from saved position to mdat end
        uint64_t posEnd = _posMDAT + lenMDAT;
        uint32_t cRead = (uint32_t)(posEnd - pos);
        [_inputFile seekToFileOffset:pos];
        [self readAndDeliver:cRead];
        
        // close and remove file
        [_inputFile closeFile];
    }

    _foundMDAT = false;
    _bytesToNextAtom = 0;
    [[NSFileManager defaultManager] removeItemAtPath:oldPath error:nil];
    
    
    // open new file and set up dispatch source
    _inputFile = [NSFileHandle fileHandleForReadingAtPath:_writer.path];
    _readSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_READ, [_inputFile fileDescriptor], 0, _readQueue);
    dispatch_source_set_event_handler(_readSource, ^{
        [self onFileUpdate];
    });
    dispatch_resume(_readSource);
    _swapping = NO;
}


- (void)readAndDeliver:(uint32_t)cReady offset:(size_t)offset withSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    NSLog(@"read and deliver - cReady: %d,  offset: %d", cReady, offset);
    while (cReady > _lengthSize) {
        size_t lengthAtOffset = 0;
        char *pointer;
        CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
        CMBlockBufferGetDataPointer(blockBuffer, offset, &lengthAtOffset, NULL, &pointer);
        
        char *lenFieldPointer = (char*)malloc(_lengthSize);
        memcpy(lenFieldPointer, pointer, _lengthSize);
        offset += _lengthSize;
        
        cReady -= _lengthSize;
        unsigned int lenNALU = to_host((unsigned char*)lenFieldPointer);
        
        if (lenNALU > cReady) {
            offset -= 4;
            break;
        }
        
        CMBlockBufferGetDataPointer(blockBuffer, offset, &lengthAtOffset, NULL, &pointer);
        char *naluPointer = (char*)malloc(lenNALU);
        memcpy(naluPointer, pointer, lenNALU);
        NSData *nalu = [NSData dataWithBytes:naluPointer length:lenNALU];
        
        cReady -= lenNALU;
        [self onNALU:nalu];
        
        free(naluPointer);
        free(lenFieldPointer);
    }
}

- (void) readAndDeliver:(uint32_t) cReady
{
    NSLog(@"length size: %d", _lengthSize);
    // Identify the individual NALUs and extract them
    while (cReady > _lengthSize)
    {
        NSData* lenField = [_inputFile readDataOfLength:_lengthSize];
        cReady -= _lengthSize;
        unsigned char* p = (unsigned char*) [lenField bytes];
        unsigned int lenNALU = to_host(p);
        
        if (lenNALU > cReady)
        {
            // whole NALU not present -- seek back to start of NALU and wait for more
            [_inputFile seekToFileOffset:[_inputFile offsetInFile] - 4];
            break;
        }
        NSData* nalu = [_inputFile readDataOfLength:lenNALU];
        cReady -= lenNALU;
        
        [self onNALU:nalu];
    }
}

- (void)encoder:(LiveEncoder*)encoder didEncodeSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!CMSampleBufferDataIsReady(sampleBuffer)) {
        NSLog(@"sample buffer data IS NOT READY");
    }
    
    
    
    // In this example we will use a NSMutableData object to store the
    // elementary stream.
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
    
//    NSLog(@"elementary stream: %@", elementaryStream);
    if (!_pendingNALU) {
        _pendingNALU = [NSMutableArray new];
    }
    [_pendingNALU removeAllObjects];
    [_pendingNALU addObject:elementaryStream];
//    elementaryStream;
    [self onEncodedFrame];
    return;
//    if (_lengthSize == 0) { return; }
    
    CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    NSLog(@"presentation time stamp: %f", (pts.value));
    const uint8_t *paramenterSetPointerOut =  NULL;
    size_t parameterSetSizeOut,parameterSizeCountOut;
    int nalUnitHeaderLengthOut;
    CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
    OSStatus status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(fdesc, 0, &paramenterSetPointerOut,&parameterSetSizeOut, &parameterSizeCountOut, &nalUnitHeaderLengthOut);

    _lengthSize = nalUnitHeaderLengthOut;
    /*
    NSMutableData *data = [NSMutableData new];
    
    [data appendBytes:paramenterSetPointerOut length:parameterSetSizeOut];
    NSLog(@"param 1: %d", paramenterSetPointerOut);
    status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(fdesc, 1, &paramenterSetPointerOut,&parameterSetSizeOut, &parameterSizeCountOut, &nalUnitHeaderLengthOut);
    [data appendBytes:paramenterSetPointerOut length:parameterSetSizeOut];
    NSLog(@"param 2: %d", paramenterSetPointerOut);
*/
    
//    NSLog(@"nalUnitHeaderLengthOut: %d", nalUnitHeaderLengthOut);
//    NSLog(@"parameter set: %d", paramenterSetPointerOut);
//    NSLog(@"parameter size count: %d", parameterSizeCountOut);
//    NSLog(@"extensions: %@", CMFormatDescriptionGetExtensions(fdesc));
    CFPropertyListRef dict = CMFormatDescriptionGetExtension(fdesc, kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms);
    NSDictionary *d = (__bridge NSDictionary*)dict;
    _avcC = [d objectForKey:@"avcC"];
//    NSLog(@"avcc: %@", CMFormatDescriptionGetExtension(fdesc, kCMFormatDescriptionExtension_SampleDescriptionExtensionAtoms));
    CMBlockBufferRef blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer);
//    NSLog(@"block buffer data length: %d", CMBlockBufferGetDataLength(blockBuffer));
    int cReady = 0;
    size_t lengthAtOffset = 0;
    size_t totalLength = 0;
    char *pointer;
    size_t offset = 0;
    if (CMBlockBufferGetDataPointer(blockBuffer, offset, &lengthAtOffset, &totalLength, &pointer) != noErr) {
        NSLog(@"error getting data pointer");
    }
    cReady = totalLength;
//    NSLog(@"bytes: %@", pointer);
//    NSData *data = [NSData dataWithBytes:pointer length:totalLength];
//    [data appendBytes:pointer length:totalLength];
//    [self onNALU:data];
//    if (!self.dataBuffer) { self.dataBuffer = [NSMutableData new]; }
//    [self.dataBuffer appendBytes:pointer length:totalLength];
//    
//    if (_needParams) { return; }
//    
//    cReady = self.dataBuffer.length - self.dataReadOffset;
//    while (!_foundMDAT && cReady > 8) {
//        if (_bytesToNextAtom == 0) {
//            NSLog(@"read offset: %d", self.dataReadOffset);
//            
//            NSData *hdr = [self.dataBuffer subdataWithRange:NSMakeRange(self.dataReadOffset, 8)];
//            self.dataReadOffset += 8;
//            NSLog(@"hdr length: %d", hdr.length);
//            cReady -= 8;
//            unsigned char* p = (unsigned char*) [hdr bytes];
//            NSLog(p == NULL ? @"p is NULL" : @"p is not NULL");
//            int lenAtom = to_host(p);
//            NSLog(@"lenAtom: %d", lenAtom);
//            unsigned int nameAtom = to_host(p+4);
//            NSLog(@"nameAtom: %d", nameAtom);
//            NSLog(@"cReady: %d", cReady);
//            if (nameAtom == (unsigned int)('mdat'))
//            {
//                _foundMDAT = true;
//                _posMDAT = [_inputFile offsetInFile] - 8;
//            }
//            else
//            {
//                _bytesToNextAtom = lenAtom - 8;
//            }
//        }
//        if (_bytesToNextAtom > 0)
//        {
//            int cThis = cReady < _bytesToNextAtom ? cReady :_bytesToNextAtom;
//            _bytesToNextAtom -= cThis;
//            offset += cThis;
//            self.dataReadOffset += cThis;
//            cReady -= cThis;
//        }
//    }
//    
//    if (!_foundMDAT)
//    {
//        return;
//    }
    
    // the mdat must be just encoded video.
    [self readAndDeliver:cReady offset:offset withSampleBuffer:sampleBuffer];

}

- (void) onFileUpdate
{
    // called whenever there is more data to read in the main encoder output file.
    
    struct stat s;
    fstat([_inputFile fileDescriptor], &s);
    int cReady = s.st_size - [_inputFile offsetInFile];
    
    // locate the mdat atom if needed
    while (!_foundMDAT && (cReady > 8))
    {
        if (_bytesToNextAtom == 0)
        {
            NSLog(@"offset in file: %d", [_inputFile offsetInFile]);
            NSData* hdr = [_inputFile readDataOfLength:8];
            cReady -= 8;
            unsigned char* p = (unsigned char*) [hdr bytes];
            int lenAtom = to_host(p);
            unsigned int nameAtom = to_host(p+4);
            
            NSLog(@"len: %d", lenAtom);
            NSLog(@"name: %d", nameAtom);
            
            if (nameAtom == (unsigned int)('mdat'))
            {
                _foundMDAT = true;
                _posMDAT = [_inputFile offsetInFile] - 8;
            }
            else
            {
                _bytesToNextAtom = lenAtom - 8;
            }
        }
        if (_bytesToNextAtom > 0)
        {
            int cThis = cReady < _bytesToNextAtom ? cReady :_bytesToNextAtom;
            _bytesToNextAtom -= cThis;
            [_inputFile seekToFileOffset:[_inputFile offsetInFile]+cThis];
            cReady -= cThis;
        }
    }
    if (!_foundMDAT)
    {
        return;
    }
    
    // the mdat must be just encoded video.
    [self readAndDeliver:cReady];
}

- (void) onEncodedFrame
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
        NSLog(@"pts val: %d", pts);
        _outputBlock(_pendingNALU, pts);
    }
}

// combine multiple NALUs into a single frame, and in the process, convert to BSF
// by adding 00 00 01 startcodes before each NALU.
- (void) onNALU:(NSData*) nalu
{
    unsigned char* pNal = (unsigned char*)[nalu bytes];
    int idc = pNal[0] & 0x60;
    int naltype = pNal[0] & 0x1f;

    if (_pendingNALU)
    {
        NALUnit nal(pNal, [nalu length]);
        NSLog(@"type: %d", nal.Type());
        // we have existing data —is this the same frame?
        // typically there are a couple of NALUs per frame in iOS encoding.
        // This is not general-purpose: it assumes that arbitrary slice ordering is not allowed.
        BOOL bNew = NO;
        if ((idc != _prev_nal_idc) && ((idc * _prev_nal_idc) == 0))
        {
            bNew = YES;
        }
        else if ((naltype != _prev_nal_type) && ((naltype == 5) || (_prev_nal_type == 5)))
        {
            bNew = YES;
        }
        else if ((naltype >= 1) && (naltype <= 5))
        {
            nal.Skip(8);
            int first_mb = nal.GetUE();
            if (first_mb == 0)
            {
                bNew = YES;
            }
        }
        if (bNew)
        {
            [self onEncodedFrame];
            _pendingNALU = nil;
        }
    }
    _prev_nal_type = naltype;
    _prev_nal_idc = idc;
    if (_pendingNALU == nil)
    {
        _pendingNALU = [NSMutableArray arrayWithCapacity:2];
    }
    [_pendingNALU addObject:nalu];
}

- (NSData*) getConfigData
{
    NSLog(@"+++++++======= avcc: %@", _avcC);
    return [_avcC copy];
}

- (void) shutdown
{
    @synchronized(self)
    {
        _readSource = nil;
        if (_headerWriter)
        {
            [_headerWriter finishWithCompletionHandler:^{
                _headerWriter = nil;
            }];
        }
        if (_writer)
        {
            [_writer finishWithCompletionHandler:^{
                _writer = nil;
            }];
        }
        // !! wait for these to finish before returning and delete temp files
    }
}

@end
