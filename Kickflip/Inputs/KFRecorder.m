//
//  KFRecorder.m
//  FFmpegEncoder
//
//  Created by Christopher Ballinger on 1/16/14.
//  Copyright (c) 2014 Christopher Ballinger. All rights reserved.
//

#import "KFRecorder.h"
#import "KFAACEncoder.h"
#import "KFH264Encoder.h"
#import "KFHLSMonitor.h"
#import "KFH264Encoder.h"
#import "KFHLSWriter.h"
#import "KFLog.h"
#import "KFAPIClient.h"
#import "KFS3EndpointResponse.h"

@interface KFRecorder()
@property (nonatomic) BOOL shouldBroadcast;
@end

@implementation KFRecorder

- (id) init {
    if (self = [super init]) {
        self.audioSampleRate = 44100;
        self.videoHeight = 720;
        self.videoWidth = 1280;
        [self setupSession];
        [self setupEncoders];
    }
    return self;
}

- (AVCaptureDevice *)audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0)
        return [devices objectAtIndex:0];
    
    return nil;
}

- (void) setupHLSWriterWithEndpoint:(KFS3EndpointResponse*)endpoint {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *folderName = [NSString stringWithFormat:@"%@.hls", endpoint.uuid];
    NSString *hlsDirectoryPath = [basePath stringByAppendingPathComponent:folderName];
    [[NSFileManager defaultManager] createDirectoryAtPath:hlsDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    self.hlsWriter = [[KFHLSWriter alloc] initWithDirectoryPath:hlsDirectoryPath];
    [_hlsWriter addVideoStreamWithWidth:self.videoWidth height:self.videoHeight];
    [_hlsWriter addAudioStreamWithSampleRate:self.audioSampleRate];

}

- (void) setupEncoders {
    _h264Encoder = [[KFH264Encoder alloc] initWithWidth:self.videoWidth height:self.videoHeight];
    _h264Encoder.delegate = self;
    
    _aacEncoder = [[KFAACEncoder alloc] init];
    _aacEncoder.delegate = self;
    _aacEncoder.addADTSHeader = YES;
}

- (void) setupAudioCapture {

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
}

#pragma mark KFEncoderDelegate method
- (void) encoder:(KFEncoder *)encoder encodedData:(NSData *)data pts:(CMTime)pts {
    if (encoder == _h264Encoder) {
        [_hlsWriter processEncodedData:data presentationTimestamp:pts streamIndex:0];
    } else if (encoder == _aacEncoder) {
        [_hlsWriter processEncodedData:data presentationTimestamp:pts streamIndex:1];
    }
}

#pragma mark AVCaptureOutputDelegate method
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

- (void) setupSession {
    _session = [[AVCaptureSession alloc] init];
    [self setupVideoCapture];
    [self setupAudioCapture];

    // start capture and a preview layer
    [_session startRunning];

    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void) startRecording {
    [[KFAPIClient sharedClient] requestRecordingEndpoint:^(KFEndpointResponse *endpointResponse, NSError *error) {
        if (error) {
            DDLogError(@"Error fetching endpoint: %@", error);
            return;
        }
        if ([endpointResponse isKindOfClass:[KFS3EndpointResponse class]]) {
            
            KFS3EndpointResponse *s3Endpoint = (KFS3EndpointResponse*)endpointResponse;
            [self setupHLSWriterWithEndpoint:s3Endpoint];
            
            [[KFHLSMonitor sharedMonitor] monitorFolderPath:_hlsWriter.directoryPath endpoint:s3Endpoint];
            
            NSError *error = nil;
            [_hlsWriter prepareForWriting:&error];
            if (error) {
                DDLogError(@"Error preparing for writing: %@", error);
            }
            self.shouldBroadcast = YES;
            if (self.delegate) {
                [self.delegate recorderDidFinishRecording:self];
            }
        }
    }];
    
}

- (void) stopRecording {
    [_session stopRunning];
    self.shouldBroadcast = NO;
    NSError *error = nil;
    [_hlsWriter finishWriting:&error];
    if (error) {
        DDLogError(@"Error stop recording: %@", error);
    }
}

@end
