#import "VTPCompressionSession.h"

// kVTCompressionPropertyKey_PixelBufferPoolIsShared Read-only, Boolean
	
// kVTCompressionPropertyKey_VideoEncoderPixelBufferAttributes Read-only, CFDictionary

// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_Depth VT_AVAILABLE_STARTING(10_8); // Read/write, CFNumber (CMPixelFormatType), Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_MaxFrameDelayCount VT_AVAILABLE_STARTING(10_8); // Read/write, CFNumber, Optional
//	enum { kVTUnlimitedFrameDelayCount = -1 };
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_MaxH264SliceBytes VT_AVAILABLE_STARTING(10_8); // Read/write, CFNumber<SInt32>, Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_SourceFrameCount VT_AVAILABLE_STARTING(10_8); // Read/write, CFNumber, Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_ExpectedFrameRate VT_AVAILABLE_STARTING(10_8); // Read/write, CFNumber, Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_ExpectedDuration VT_AVAILABLE_STARTING(10_8); // Read/write, CFNumber(seconds), Optional
	
#define VTPVideoEncoderSpecificationEnableHardwareAcceleratedVideoEncoder ((__bridge NSString *)kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder)

#define VTPVideoEncoderSpecificationRequireHardwareAcceleratedVideoEncoder ((__bridge NSString *)kVTVideoEncoderSpecification_RequireHardwareAcceleratedVideoEncoder)

// VT_EXPORT const CFStringRef kVTEncodeFrameOptionKey_ForceKeyFrame VT_AVAILABLE_STARTING(10_8); //  CFBoolean
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_CleanAperture VT_AVAILABLE_STARTING(10_8); // Read/write, CFDictionary (see CMFormatDescription.h), Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_PixelAspectRatio VT_AVAILABLE_STARTING(10_8); // Read/write, CFDictionary (see CMFormatDescription.h), Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_FieldCount VT_AVAILABLE_STARTING(10_8); // Read/write, CFNumber (see kCMFormatDescriptionExtension_FieldCount), Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_FieldDetail VT_AVAILABLE_STARTING(10_8); // Read/write, CFString (see kCMFormatDescriptionExtension_FieldDetail), Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_AspectRatio16x9 VT_AVAILABLE_STARTING(10_8); // Read/write, CFBoolean, Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_ProgressiveScan VT_AVAILABLE_STARTING(10_8); // Read/write, CFBoolean, Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_ColorPrimaries VT_AVAILABLE_STARTING(10_8); // Read/write, CFString (see kCMFormatDescriptionExtension_ColorPrimaries), Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_TransferFunction VT_AVAILABLE_STARTING(10_8); // Read/write, CFString (see kCMFormatDescriptionExtension_TransferFunction), Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_YCbCrMatrix VT_AVAILABLE_STARTING(10_8); // Read/write, CFString (see kCMFormatDescriptionExtension_YCbCrMatrix), Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_ICCProfile VT_AVAILABLE_STARTING(10_8); // Read/write, CFData (see kCMFormatDescriptionExtension_ICCProfile), Optional
	
// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_PixelTransferProperties VT_AVAILABLE_STARTING(10_8); // Read/Write, CFDictionary containing properties from VTPixelTransferProperties.h.


@interface VTPCompressionSession (Properties)

/**
 * @see kVTCompressionPropertyKey_NumberOfPendingFrames
 */
- (NSUInteger)numberOfPendingFrames;

/**
 * @see kVTCompressionPropertyKey_MaxKeyFrameInterval
 */
- (NSUInteger)maxKeyframeInterval;

/**
 * @see kVTCompressionPropertyKey_MaxKeyFrameInterval
 */
- (BOOL)setMaxKeyframeInterval:(NSUInteger)maxKeyFrameInterval error:(NSError **)error;

/**
 * @see kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration
 */
- (NSTimeInterval)maxKeyframeIntervalDuration;

/**
 * @see kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration
 */
- (BOOL)setMaxKeyframeIntervalDuration:(NSTimeInterval)maxKeyFrameIntervalDuration error:(NSError **)error;

/**
 * @see kVTCompressionPropertyKey_AllowTemporalCompression
 */
- (BOOL)allowTemporalCompression;

/**
 * @see kVTCompressionPropertyKey_AllowTemporalCompression
 */
- (BOOL)setAllowTemporalCompression:(BOOL)allowTemporalCompression error:(NSError **)error;

/**
 * @see kVTCompressionPropertyKey_AllowFrameReordering
 */
- (BOOL)allowFrameReordering;

/**
 * @see kVTCompressionPropertyKey_AllowFrameReordering
 */
- (BOOL)setAllowFrameReordering:(BOOL)allowFrameReordering error:(NSError **)error;

/**
 * @see kVTCompressionPropertyKey_AverageBitRate
 */
- (SInt32)averageBitrate;

/**
 * @see kVTCompressionPropertyKey_AverageBitRate
 */
- (BOOL)setAverageBitrate:(SInt32)averageBitrate error:(NSError **)error;

/**
 * @see kVTCompressionPropertyKey_DataRateLimits
 */
- (NSArray *)dataRateLimits;

/**
 * @see kVTCompressionPropertyKey_DataRateLimits
 */
- (BOOL)setDataRateLimits:(NSArray *)dataRateLimits error:(NSError **)error;

/**
 * calls setDataRateLimits:@[ constantBitrate, interval ]
 * @see kVTCompressionPropertyKey_DataRateLimits
 */
- (BOOL)setConstantBitrate:(SInt32)constantBitrate forInterval:(NSTimeInterval)interval error:(NSError **)error;

/**
 * calls setDataRateLimits:@[ constantBitrate, 1.0 ]
 * @see kVTCompressionPropertyKey_DataRateLimits
 */
- (BOOL)setConstantBitrate:(SInt32)constantBitrate error:(NSError **)error;

/**
 * @see kVTCompressionPropertyKey_Quality
 */
- (float)quality;

/**
 * @see kVTCompressionPropertyKey_Quality
 */
- (BOOL)setQuality:(float)quality error:(NSError **)error;

// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_MoreFramesBeforeStart VT_AVAILABLE_STARTING(10_8); // Read/write, CFBoolean, Optional

// VT_EXPORT const CFStringRef kVTCompressionPropertyKey_MoreFramesAfterEnd VT_AVAILABLE_STARTING(10_8); // Read/write, CFBoolean, Optional

/**
 * @see kVTCompressionPropertyKey_ProfileLevel
 */
- (NSString *)profileLevel;

/**
 * @see kVTCompressionPropertyKey_ProfileLevel
 */
- (BOOL)setProfileLevel:(NSString *)profileLevel error:(NSError **)error;

/**
 * @see kVTCompressionPropertyKey_H264EntropyMode
 */
- (NSString *)H264EntropyMode;

/**
 * @see kVTCompressionPropertyKey_H264EntropyMode
 */
- (BOOL)setH264EntropyMode:(NSString *)H264EntropyMode error:(NSError **)error;

/**
 * @see kVTCompressionPropertyKey_RealTime
 */
- (BOOL)realtime;

/**
 * @see kVTCompressionPropertyKey_RealTime
 */
- (BOOL)setRealtime:(BOOL)realtime error:(NSError **)error;

/**
 * @see kVTCompressionPropertyKey_UsingHardwareAcceleratedVideoEncoder
 */
- (BOOL)usingHardwareAcceleratedVideoEncoder;

@end
