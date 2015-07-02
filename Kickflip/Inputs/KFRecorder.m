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
#import "KFS3Stream.h"
#import "KFFrame.h"
#import "KFVideoFrame.h"
#import "Kickflip.h"
#import "Endian.h"

@interface KFRecorder() {
    AVAssetWriter *_assetWriter;
    AVAssetWriterInput *_assetWriterAudioIn;
    AVAssetWriterInput *_assetWriterVideoIn;
    dispatch_queue_t _movieWritingQueue;
    BOOL _readyToRecordAudio;
    BOOL _readyToRecordVideo;
    NSURL *_outputFileURL;
}

@property (nonatomic) double minBitrate;
@property (nonatomic) BOOL hasScreenshot;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation KFRecorder

- (void) dealloc {
//    NSLog(@"KFRecorder dealloc");
}

- (id) init {
    if (self = [super init]) {
        _minBitrate = 120 * 1000;
        _outputFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"recording.mp4"]];
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

- (void) setupSession {
    _session = [[AVCaptureSession alloc] init];
    _movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);
    
    [self setupVideoCapture];
    [self setupAudioCapture];
    
    // start capture and a preview layer
    [_session startRunning];
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

- (void) setupHLSWriterWithEndpoint:(KFS3Stream*)endpoint {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSString *folderName = [NSString stringWithFormat:@"%@.hls", endpoint.streamID];
    NSString *hlsDirectoryPath = [basePath stringByAppendingPathComponent:folderName];
    [[NSFileManager defaultManager] createDirectoryAtPath:hlsDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    self.hlsWriter = [[KFHLSWriter alloc] initWithDirectoryPath:hlsDirectoryPath];
    [_hlsWriter addVideoStreamWithWidth:self.videoWidth height:self.videoHeight];
    [_hlsWriter addAudioStreamWithSampleRate:self.audioSampleRate];

}

- (void) setupEncoders {
    self.audioSampleRate = 44100;

    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        self.videoHeight = 568;
        self.videoWidth = 320;
    } else {
        self.videoHeight = 320;
        self.videoWidth = 568;
    }
    
    int audioBitrate = 56 * 1000; // 56 Kbps
    int maxBitrate = [Kickflip maxBitrate];
    int videoBitrate = maxBitrate - audioBitrate;
    _h264Encoder = [[KFH264Encoder alloc] initWithBitrate:videoBitrate width:self.videoWidth height:self.videoHeight];
    _h264Encoder.delegate = self;
    
    _aacEncoder = [[KFAACEncoder alloc] initWithBitrate:audioBitrate sampleRate:self.audioSampleRate channels:1];
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
    _videoOutput.videoSettings = @{ (NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA) };
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    _videoConnection.videoOrientation = [self avOrientationForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation];
}

- (BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription {
    // Create audio output settings dictionary which would be used to configure asset writer input
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
    
    NSData *currentChannelLayoutData = nil;
    // AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
    if ( currentChannelLayout && aclSize > 0 )
        currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
    else
        currentChannelLayoutData = [NSData data];
    
    NSDictionary *audioCompressionSettings = @{AVFormatIDKey : [NSNumber numberWithInteger:kAudioFormatMPEG4AAC],
                                               AVSampleRateKey : [NSNumber numberWithFloat:currentASBD->mSampleRate],
                                               AVEncoderBitRatePerChannelKey : [NSNumber numberWithInt:64000],
                                               AVNumberOfChannelsKey : [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame],
                                               AVChannelLayoutKey : currentChannelLayoutData};
    
    if ([_assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio]) {
        // Intialize asset writer audio input with the above created settings dictionary
        _assetWriterAudioIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
        _assetWriterAudioIn.expectsMediaDataInRealTime = YES;
        
        // Add asset writer input to asset writer
        if ([_assetWriter canAddInput:_assetWriterAudioIn]) {
            [_assetWriter addInput:_assetWriterAudioIn];
        } else {
            NSLog(@"Couldn't add asset writer audio input.");
            return NO;
        }
    } else {
        NSLog(@"Couldn't apply audio output settings.");
        return NO;
    }
    
    return YES;
}

- (BOOL)setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription {
    // Create video output settings dictionary which would be used to configure asset writer input
    CGFloat bitsPerPixel;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
    NSUInteger numPixels = dimensions.width * dimensions.height;
    NSUInteger bitsPerSecond;
    
    // Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
    if ( numPixels < (640 * 480) )
        bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
    else
        bitsPerPixel = 11.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
    
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *videoCompressionSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                               AVVideoWidthKey : [NSNumber numberWithInteger:dimensions.width],
                                               AVVideoHeightKey : [NSNumber numberWithInteger:dimensions.height],
                                               AVVideoCompressionPropertiesKey : @{ AVVideoAverageBitRateKey : [NSNumber numberWithInteger:bitsPerSecond],
                                                                                    AVVideoMaxKeyFrameIntervalKey :[NSNumber numberWithInteger:30]}};
    
    if ([_assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo]) {
        // Intialize asset writer video input with the above created settings dictionary
        _assetWriterVideoIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        _assetWriterVideoIn.expectsMediaDataInRealTime = YES;
        _assetWriterVideoIn.transform = [self transformFromCurrentVideoOrientationToOrientation:[self avOrientationForInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation]];
        
        // Add asset writer input to asset writer
        if ([_assetWriter canAddInput:_assetWriterVideoIn]) {
            [_assetWriter addInput:_assetWriterVideoIn];
        } else {
            NSLog(@"Couldn't add asset writer video input.");
            return NO;
        }
    } else {
        NSLog(@"Couldn't apply video output settings.");
        return NO;
    }
    
    return YES;
}

#pragma mark - KFEncoderDelegate

- (void) encoder:(KFEncoder*)encoder encodedFrame:(KFFrame *)frame {
    if (encoder == _h264Encoder) {
        KFVideoFrame *videoFrame = (KFVideoFrame*)frame;
        [_hlsWriter processEncodedData:videoFrame.data presentationTimestamp:videoFrame.pts streamIndex:0 isKeyFrame:videoFrame.isKeyFrame];
    } else if (encoder == _aacEncoder) {
        [_hlsWriter processEncodedData:frame.data presentationTimestamp:frame.pts streamIndex:1 isKeyFrame:NO];
    }
}

#pragma mark - AVCaptureOutputDelegate

- (void) captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if (!_isRecording) {
        return;
    }
    
    // pass frame to encoders
    if (connection == _videoConnection) {
        if (!_hasScreenshot) {
            UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
            NSString *path = [self.hlsWriter.directoryPath stringByAppendingPathComponent:@"thumb.jpg"];
            NSData *imageData = UIImageJPEGRepresentation(image, 0.7);
            [imageData writeToFile:path atomically:NO];
            _hasScreenshot = YES;
        }
        
        [_h264Encoder encodeSampleBuffer:sampleBuffer];
    } else if (connection == _audioConnection) {
        [_aacEncoder encodeSampleBuffer:sampleBuffer];
    }

    // pass frame to disk
    if (_saveToCameraRoll) {
        CFRetain(sampleBuffer);
        dispatch_async(_movieWritingQueue, ^{
            if (_assetWriter) {
                if (connection == _videoConnection) {
                    if (!_readyToRecordVideo)
                        _readyToRecordVideo = [self setupAssetWriterVideoInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
                    
                    if ([self inputsReadyToRecord])
                        [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo];
                } else if (connection == _audioConnection) {
                    if (!_readyToRecordAudio)
                        _readyToRecordAudio = [self setupAssetWriterAudioInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
                    
                    if ([self inputsReadyToRecord])
                        [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
                }
            }
            
            CFRelease(sampleBuffer);
        });
    }
}

#pragma mark - AVCaptureOutputDelegate Utilities

// Create a UIImage from sample buffer data
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // Release the Quartz image
    CGImageRelease(quartzImage);
    
    return (image);
}

- (void) uploader:(KFHLSUploader *)uploader liveManifestReadyAtURL:(NSURL *)manifestURL {
    if (self.delegate && [self.delegate respondsToSelector:@selector(recorder:streamReadyAtURL:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate recorder:self streamReadyAtURL:manifestURL];
        });
    }
    DDLogVerbose(@"Manifest ready at URL: %@", manifestURL);
}

- (void) uploader:(KFHLSUploader*)uploader didUploadPartOfASegmentAtUploadSpeed:(double)uploadSpeed {
    if ([Kickflip useAdaptiveBitrate]) {
        double currentUploadBitrate = uploadSpeed * 8 * 1024; // bps
        double maxBitrate = [Kickflip maxBitrate];
        
        double newBitrate = currentUploadBitrate * 0.5;
        if (newBitrate > maxBitrate) {
            newBitrate = maxBitrate;
        }
        if (newBitrate < _minBitrate) {
            newBitrate = _minBitrate;
        }
        double newVideoBitrate = newBitrate - self.aacEncoder.bitrate;
        
        DDLogInfo(@"old video bitrate: %d, new video bitrate: %f", self.h264Encoder.bitrate, newVideoBitrate);
        
        self.h264Encoder.bitrate = newVideoBitrate;
    }
}

- (void) uploader:(KFHLSUploader *)uploader didUploadSegmentAtURL:(NSURL *)segmentURL uploadSpeed:(double)uploadSpeed numberOfQueuedSegments:(NSUInteger)numberOfQueuedSegments {
    DDLogInfo(@"Uploaded segment %@ @ %f KB/s, numberOfQueuedSegments %d", segmentURL, uploadSpeed, numberOfQueuedSegments);
}

- (void) locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    self.lastLocation = [locations lastObject];
    [self setStreamStartLocation];
}

- (void) setStreamStartLocation {
    if (!self.lastLocation) {
        return;
    }
    if (self.stream && !self.stream.startLocation) {
        self.stream.startLocation = self.lastLocation;
        [[KFAPIClient sharedClient] updateMetadataForStream:self.stream callbackBlock:^(KFStream *updatedStream, NSError *error) {
            if (error) {
                DDLogError(@"Error updating stream startLocation: %@", error);
            }
        }];
        [self reverseGeocodeStream:self.stream];
    }
}

- (void) reverseGeocodeStream:(KFStream*)stream {
    CLLocation *location = nil;
    CLLocation *endLocation = stream.endLocation;
    CLLocation *startLocation = stream.startLocation;
    if (startLocation) {
        location = startLocation;
    }
    if (endLocation) {
        location = endLocation;
    }
    if (!location) {
        return;
    }
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error) {
            DDLogError(@"Error geocoding stream: %@", error);
            return;
        }
        if (placemarks.count == 0) {
            return;
        }
        CLPlacemark *placemark = [placemarks firstObject];
        stream.city = placemark.locality;
        stream.state = placemark.administrativeArea;
        stream.country = placemark.country;
        [[KFAPIClient sharedClient] updateMetadataForStream:stream callbackBlock:^(KFStream *updatedStream, NSError *error) {
            if (error) {
                DDLogError(@"Error updating stream geocoder info: %@", error);
            }
        }];
    }];
}

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType {
    CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    if ( _assetWriter.status == AVAssetWriterStatusUnknown ) {
        if ([_assetWriter startWriting]) {
            [_assetWriter startSessionAtSourceTime:presentationTime];
        } else {
            NSLog(@"Error writing initial buffer");
        }
    }
    
    if ( _assetWriter.status == AVAssetWriterStatusWriting ) {
        if (mediaType == AVMediaTypeVideo) {
            if (_assetWriterVideoIn.readyForMoreMediaData) {
                if (![_assetWriterVideoIn appendSampleBuffer:sampleBuffer]) {
                    NSLog(@"Error writing video buffer");
                }
            }
        } else if (mediaType == AVMediaTypeAudio) {
            if (_assetWriterAudioIn.readyForMoreMediaData) {
                if (![_assetWriterAudioIn appendSampleBuffer:sampleBuffer]) {
                    NSLog(@"Error writing audio buffer");
                }
            }
        }
    }
    
    if (_assetWriter.status == AVAssetWriterStatusFailed) {
        NSLog(@"writeSampleBuffer writer error: %@", _assetWriter.error.localizedDescription);
    }
}

- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self removeFile:_outputFileURL];
}

- (BOOL)inputsReadyToRecord
{
    return (_readyToRecordAudio && _readyToRecordVideo);
}

#pragma mark - General Utilities

- (void) startRecording {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self.locationManager startUpdatingLocation];
    
    [[KFAPIClient sharedClient] startNewStream:^(KFStream *endpointResponse, NSError *error) {
        if (error) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(recorderDidStartRecording:error:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate recorderDidStartRecording:self error:error];
                });
            }
            return;
        }
        self.stream = endpointResponse;
        [self setStreamStartLocation];
        if ([endpointResponse isKindOfClass:[KFS3Stream class]]) {
            KFS3Stream *s3Endpoint = (KFS3Stream*)endpointResponse;
            s3Endpoint.streamState = KFStreamStateStreaming;
            [self setupHLSWriterWithEndpoint:s3Endpoint];
            
            [[KFHLSMonitor sharedMonitor] startMonitoringFolderPath:_hlsWriter.directoryPath endpoint:s3Endpoint delegate:self];
            
            NSError *error = nil;
            [_hlsWriter prepareForWriting:&error];
            if (error) {
                DDLogError(@"Error preparing for writing: %@", error);
            }
            
            self.isRecording = YES;
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(recorderDidStartRecording:error:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.delegate recorderDidStartRecording:self error:nil];
                });
            }
        }
    }];
    
    if (_saveToCameraRoll) {
        dispatch_async(_movieWritingQueue, ^{
            [self removeFile:_outputFileURL];
            NSError *error;
            _assetWriter = [[AVAssetWriter alloc] initWithURL:_outputFileURL fileType:AVFileTypeQuickTimeMovie error:&error];
            if (error)
                NSLog(@"Error creating AVAssetWriter: %@", error);
        });
    }
}

- (void) stopRecording {
    [self.locationManager stopUpdatingLocation];
    
    if (self.lastLocation) {
        self.stream.endLocation = self.lastLocation;
        [[KFAPIClient sharedClient] updateMetadataForStream:self.stream callbackBlock:^(KFStream *updatedStream, NSError *error) {
            if (error) {
                DDLogError(@"Error updating stream endLocation: %@", error);
            }
        }];
    }
    [_session stopRunning];
    self.isRecording = NO;
    
    NSError *error = nil;
    [_hlsWriter finishWriting:&error];
    if (error) {
        DDLogError(@"Error stop recording: %@", error);
    }
    
    [[KFAPIClient sharedClient] stopStream:self.stream callbackBlock:^(BOOL success, NSError *error) {
        if (!success) {
            DDLogError(@"Error stopping stream: %@", error);
        } else {
            DDLogVerbose(@"Stream stopped: %@", self.stream.streamID);
        }
    }];
    
    if ([self.stream isKindOfClass:[KFS3Stream class]]) {
        [[KFHLSMonitor sharedMonitor] finishUploadingContentsAtFolderPath:_hlsWriter.directoryPath endpoint:(KFS3Stream*)self.stream];
    }
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(recorderDidFinishRecording:error:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate recorderDidFinishRecording:self error:error];
        });
    }
    
    if (_saveToCameraRoll) {
        dispatch_async(_movieWritingQueue, ^{
            [_assetWriter finishWritingWithCompletionHandler:^() {
                AVAssetWriterStatus completionStatus = _assetWriter.status;
                switch (completionStatus) {
                    case AVAssetWriterStatusCompleted: {
                        UISaveVideoAtPathToSavedPhotosAlbum(_outputFileURL.path, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
                        break;
                    }
                    case AVAssetWriterStatusFailed: {
                        NSLog(@"stopRecording writer error: %@", _assetWriter.error.localizedDescription);
                        break;
                    }
                    default:
                        break;
                }
                
                _readyToRecordVideo = NO;
                _readyToRecordAudio = NO;
                _assetWriter = nil;
            }];
        });
    }
    
    // TEL
    _hasScreenshot = NO;
}

- (AVCaptureVideoOrientation)avOrientationForInterfaceOrientation:(UIInterfaceOrientation)orientation {
    switch (orientation) {
        case UIInterfaceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            return AVCaptureVideoOrientationLandscapeLeft;
            break;
    }
}

- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation {
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // Calculate offsets from an arbitrary reference orientation (portrait)
    CGFloat orientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:orientation];
    CGFloat videoOrientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:_videoConnection.videoOrientation];
    
    // Find the difference in angle between the passed in orientation and the current video orientation
    CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
    transform = CGAffineTransformMakeRotation(angleOffset);
    
    return transform;
}

- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation {
    CGFloat angle = 0.0;
    
    switch (orientation) {
        case AVCaptureVideoOrientationPortrait:
            angle = 0.0;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        default:
            break;
    }
    
    return angle;
}

- (void)removeFile:(NSURL *)fileURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *filePath = fileURL.path;
    if ([fileManager fileExistsAtPath:filePath]) {
        NSError *error;
        BOOL success = [fileManager removeItemAtPath:filePath error:&error];
        if (!success)
            NSLog(@"Error removing file: %@", error);
    }
}

@end
