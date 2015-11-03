#import <Foundation/Foundation.h>
#import <VideoToolbox/VideoToolbox.h>

@class VTPCompressionSession;


@protocol VTPCompressionSessionDelegate <NSObject>
@required

- (void)videoCompressionSession:(VTPCompressionSession *)compressionSession didEncodeSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@optional

- (void)videoCompressionSession:(VTPCompressionSession *)compressionSession didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end


@interface VTPCompressionSession : NSObject

+ (BOOL)hasHardwareSupportForCodec:(CMVideoCodecType)codec;

- (instancetype)initWithWidth:(NSInteger)width height:(NSInteger)height codec:(CMVideoCodecType)codec error:(NSError **)error;

@property (nonatomic, weak, readonly) id<VTPCompressionSessionDelegate> delegate;
@property (nonatomic, strong, readonly) dispatch_queue_t delegateQueue;

- (void)setDelegate:(id<VTPCompressionSessionDelegate>)delegate queue:(dispatch_queue_t)queue;

- (id)valueForProperty:(NSString *)property error:(NSError **)outError;
- (BOOL)setValue:(id)value forProperty:(NSString *)property error:(NSError **)outError;

- (void)prepare;

- (BOOL)encodeSampleBuffer:(CMSampleBufferRef)sampleBuffer forceKeyframe:(BOOL)forceKeyframe;
- (BOOL)encodePixelBuffer:(CVPixelBufferRef)pixelBuffer presentationTimeStamp:(CMTime)presentationTimeStamp duration:(CMTime)duration forceKeyframe:(BOOL)forceKeyframe;

- (BOOL)finish;
- (BOOL)finishUntilPresentationTimeStamp:(CMTime)presentationTimeStamp;

@end
