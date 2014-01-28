//
//  CameraServer.m
//  Encoder Demo
//
//  Created by Geraint Davies on 19/02/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "CameraServer.h"
#import "AVEncoder.h"
#import "RTSPServer.h"
#import "NALUnit.h"
#import "HLSWriter.h"
#import "AACEncoder.h"
#import "HTTPServer.h"
#import "HLSUploader.h"

static const int VIDEO_WIDTH = 1280;
static const int VIDEO_HEIGHT = 720;
static const int SAMPLE_RATE = 44100;

static CameraServer* theServer;

@interface CameraServer  () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>
{
    AVCaptureSession* _session;
    AVCaptureVideoPreviewLayer* _preview;
    AVCaptureVideoDataOutput* _videoOutput;
    AVCaptureAudioDataOutput* _audioOutput;
    dispatch_queue_t _videoQueue;
    dispatch_queue_t _audioQueue;
    AVCaptureConnection* _audioConnection;
    AVCaptureConnection* _videoConnection;
    
    AVEncoder* _encoder;
    
    RTSPServer* _rtsp;
}

@property (nonatomic, strong) NSData *naluStartCode;
@property (nonatomic, strong) NSMutableData *videoSPSandPPS;
@property (nonatomic, strong) AACEncoder *aacEncoder;

@property (nonatomic, strong) NSFileHandle *debugFileHandle;

@property (nonatomic, strong) HTTPServer *httpServer;

@end


@implementation CameraServer

+ (void) initialize
{
    // test recommended to avoid duplicate init via subclass
    if (self == [CameraServer class])
    {
        theServer = [[CameraServer alloc] init];
    }
}

+ (CameraServer*) server
{
    return theServer;
}

- (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0)
        return [devices objectAtIndex:0];
    
    return nil;
}

- (void) setupHLSWriter {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    NSString *folderName = [NSString stringWithFormat:@"%f.hls", time];
    NSString *hlsDirectoryPath = [basePath stringByAppendingPathComponent:folderName];
    [[NSFileManager defaultManager] createDirectoryAtPath:hlsDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    self.hlsWriter = [[HLSWriter alloc] initWithDirectoryPath:hlsDirectoryPath];
}

- (void) initializeNALUnitStartCode {
    NSUInteger naluLength = 4;
    uint8_t *nalu = (uint8_t*)malloc(naluLength * sizeof(uint8_t));
    nalu[0] = 0x00;
    nalu[1] = 0x00;
    nalu[2] = 0x00;
    nalu[3] = 0x01;
    _naluStartCode = [NSData dataWithBytesNoCopy:nalu length:naluLength freeWhenDone:YES];
}

- (void) setupAudioCapture {
    _aacEncoder = [[AACEncoder alloc] init];
    // create capture device with video input
    
    /*
     * Create audio connection
     */
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    NSError *error = nil;
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting audio input device: %@", error.description);
    }
    if ([_session canAddInput:audioInput]) {
        [_session addInput:audioInput];
    }
    
    _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if ([_session canAddOutput:_audioOutput]) {
        [_session addOutput:_audioOutput];
    }
    _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
    [_hlsWriter addAudioStreamWithSampleRate:SAMPLE_RATE];
}

- (void) setupVideoCapture {
    NSError *error = nil;
    AVCaptureDevice* videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput* videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"Error getting video input device: %@", error.description);
    }
    if ([_session canAddInput:videoInput]) {
        [_session addInput:videoInput];
    }
    
    // create an output for YUV output with self as delegate
    _videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)};
    _videoOutput.videoSettings = captureSettings;
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];

    [_hlsWriter addVideoStreamWithWidth:VIDEO_WIDTH height:VIDEO_HEIGHT];

}

- (void) startup
{
    if (_session == nil)
    {
        _session = [[AVCaptureSession alloc] init];
        NSLog(@"Starting up server");
        [self initializeNALUnitStartCode];
        [self setupHLSWriter];
        [self setupVideoCapture];
        [self setupAudioCapture];
        NSError *error = nil;
        [_hlsWriter prepareForWriting:&error];
        if (error) {
            NSLog(@"Error preparing for writing: %@", error);
        }
        
        _httpServer = [[HTTPServer alloc] init];
        [_httpServer setDocumentRoot:_hlsWriter.directoryPath];
        _httpServer.port = 9001;
        [_httpServer start:&error];
        if (error) {
            NSLog(@"Error starting http server: %@", error.description);
        }
        
        _hlsUploader = [[HLSUploader alloc] initWithDirectoryPath:_hlsWriter.directoryPath remoteFolderName:_hlsWriter.uuid];
        
        // create an encoder
        _encoder = [AVEncoder encoderForHeight:VIDEO_HEIGHT andWidth:VIDEO_WIDTH];
        [_encoder encodeWithBlock:^int(NSArray* dataArray, double pts) {
            [self writeVideoFrames:dataArray pts:pts];
            //[self writeDebugFileForDataArray:dataArray pts:pts];
            if (_rtsp != nil)
            {
                _rtsp.bitrate = _encoder.bitspersecond;
                [_rtsp onVideoData:dataArray time:pts];
            }
            return 0;
        } onParams:^int(NSData *data) {
            _rtsp = [RTSPServer setupListener:data];
            return 0;
        }];
        
        // start capture and a preview layer
        [_session startRunning];
        
        
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
        

    }
}

- (void) writeVideoFrames:(NSArray*)frames pts:(double)pts {
    if (pts == 0) {
        NSLog(@"PTS of 0, skipping frame");
        return;
    }
    if (!_videoSPSandPPS) {
        NSData* config = _encoder.getConfigData;
        
        avcCHeader avcC((const BYTE*)[config bytes], [config length]);
        SeqParamSet seqParams;
        seqParams.Parse(avcC.sps());
        
        NSData* spsData = [NSData dataWithBytes:avcC.sps()->Start() length:avcC.sps()->Length()];
        NSData *ppsData = [NSData dataWithBytes:avcC.pps()->Start() length:avcC.pps()->Length()];
        
        _videoSPSandPPS = [NSMutableData dataWithCapacity:avcC.sps()->Length() + avcC.pps()->Length() + _naluStartCode.length * 2];
        [_videoSPSandPPS appendData:_naluStartCode];
        [_videoSPSandPPS appendData:spsData];
        [_videoSPSandPPS appendData:_naluStartCode];
        [_videoSPSandPPS appendData:ppsData];
    }
    
    for (NSData *data in frames) {
        unsigned char* pNal = (unsigned char*)[data bytes];
        //int idc = pNal[0] & 0x60;
        int naltype = pNal[0] & 0x1f;
        NSData *videoData = nil;
        if (naltype == 5) { // IDR
            NSMutableData *IDRData = [NSMutableData dataWithData:_videoSPSandPPS];
            [IDRData appendData:_naluStartCode];
            [IDRData appendData:data];
            videoData = IDRData;
        } else {
            NSMutableData *regularData = [NSMutableData dataWithData:_naluStartCode];
            [regularData appendData:data];
            videoData = regularData;
        }
        //NSMutableData *nalu = [[NSMutableData alloc] initWithData:_naluStartCode];
        //[nalu appendData:data];
        //NSLog(@"%f: %@", pts, videoData.description);
        [_hlsWriter processEncodedData:videoData presentationTimestamp:pts streamIndex:0];
    }
    
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // pass frame to encoder
    if (connection == _videoConnection) {
        [_encoder encodeFrame:sampleBuffer];
    } else if (connection == _audioConnection) {
        CMTime pts = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        double dPTS = (double)(pts.value) / pts.timescale;
        [_aacEncoder encodeSampleBuffer:sampleBuffer completionBlock:^(NSData *encodedData, NSError *error) {
            if (encodedData) {
                //NSLog(@"Encoded data (%d): %@", encodedData.length, encodedData.description);
                [_hlsWriter processEncodedData:encodedData presentationTimestamp:dPTS streamIndex:1];
                //[self writeDebugFileForData:encodedData pts:dPTS];
            } else {
                NSLog(@"Error encoding AAC: %@", error);
            }
        }];
    }
}

- (void) writeDebugFileForData:(NSData*)data pts:(double)pts {
    if (!_debugFileHandle) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
        NSString *folderName = [NSString stringWithFormat:@"%f.aacdebug", time];
        NSString *debugDirectoryPath = [basePath stringByAppendingPathComponent:folderName];
        [[NSFileManager defaultManager] createDirectoryAtPath:debugDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        
        NSString *fileName = @"test.aac";
        NSString *outputFilePath = [debugDirectoryPath stringByAppendingPathComponent:fileName];
        NSURL *fileURL = [NSURL fileURLWithPath:outputFilePath];
        NSError *error = nil;
        [[NSFileManager defaultManager] createFileAtPath:outputFilePath contents:nil attributes:nil];
        _debugFileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
        if (error) {
            NSLog(@"Error opening file for writing: %@", error.description);
        }
    }
    
    [_debugFileHandle writeData:data];
    [_debugFileHandle synchronizeFile];
}

- (void) shutdown
{
    NSLog(@"shutting down server");
    if (_session)
    {
        [_session stopRunning];
        _session = nil;
    }
    if (_rtsp)
    {
        [_rtsp shutdownServer];
    }
    if (_encoder)
    {
        [ _encoder shutdown];
    }
}

- (NSString*) getURL
{
    NSString* ipaddr = [RTSPServer getIPAddress];
    NSString* url = [NSString stringWithFormat:@"rtsp://%@/", ipaddr];
    return url;
}

- (AVCaptureVideoPreviewLayer*) getPreviewLayer
{
    return _preview;
}

@end
