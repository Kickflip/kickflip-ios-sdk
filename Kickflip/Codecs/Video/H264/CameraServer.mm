//
//  CameraServer.m
//  Encoder Demo
//
//  Created by Geraint Davies on 19/02/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "CameraServer.h"
#import "AVEncoder.h"
#import "HLSWriter.h"
#import "KFAACEncoder.h"
#import "HLSUploader.h"
#import "KFH264Encoder.h"

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
}

@property (nonatomic, strong) KFAACEncoder *aacEncoder;
@property (nonatomic, strong) KFH264Encoder *h264Encoder;
@property (nonatomic, strong) NSFileHandle *debugFileHandle;

@property (nonatomic) BOOL shouldBroadcast;


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



- (void) setupAudioCapture {
    _aacEncoder = [[KFAACEncoder alloc] init];
    _aacEncoder.delegate = self;
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
    
    _h264Encoder = [[KFH264Encoder alloc] initWithWidth:VIDEO_WIDTH height:VIDEO_HEIGHT];
    _h264Encoder.delegate = self;

    [_hlsWriter addVideoStreamWithWidth:VIDEO_WIDTH height:VIDEO_HEIGHT];

}

- (void) startup
{
    if (_session == nil)
    {
        _session = [[AVCaptureSession alloc] init];
        NSLog(@"Starting up server");
        [self setupHLSWriter];
        [self setupVideoCapture];
        [self setupAudioCapture];
        NSError *error = nil;
        [_hlsWriter prepareForWriting:&error];
        if (error) {
            NSLog(@"Error preparing for writing: %@", error);
        }
        
        _hlsUploader = [[HLSUploader alloc] initWithDirectoryPath:_hlsWriter.directoryPath remoteFolderName:_hlsWriter.uuid];
        
        // start capture and a preview layer
        [_session startRunning];
        
        
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        _preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
}

- (void) startBroadcast {
    _shouldBroadcast = YES;
}

- (void) stopBroadcast {
    _shouldBroadcast = NO;
}


- (void) encoder:(KFEncoder *)encoder encodedData:(NSData *)data pts:(CMTime)pts {
    double dPTS = (double)(pts.value) / pts.timescale;
    if (encoder == _h264Encoder) {
        [_hlsWriter processEncodedData:data presentationTimestamp:dPTS streamIndex:0];
    } else if (encoder == _aacEncoder) {
        [_hlsWriter processEncodedData:data presentationTimestamp:dPTS streamIndex:1];
    }
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!_shouldBroadcast) {
        return;
    }
    // pass frame to encoders
    if (connection == _videoConnection) {
        [_h264Encoder encodeSampleBuffer:sampleBuffer];
    } else if (connection == _audioConnection) {
        [_aacEncoder encodeSampleBuffer:sampleBuffer];
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
}

- (AVCaptureVideoPreviewLayer*) getPreviewLayer
{
    return _preview;
}

@end
