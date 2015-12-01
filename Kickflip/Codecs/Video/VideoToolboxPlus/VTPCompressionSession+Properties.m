#import "VTPCompressionSession+Properties.h"

#import <VideoToolbox/VideoToolbox.h>


@implementation VTPCompressionSession (Properties)

- (NSUInteger)numberOfPendingFrames
{
	NSNumber *value = [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_NumberOfPendingFrames error:nil];
	return value.unsignedIntegerValue;
}

- (NSUInteger)maxKeyframeInterval
{
	NSNumber *value = [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_MaxKeyFrameInterval error:nil];
	return value.unsignedIntegerValue;
}

- (BOOL)setMaxKeyframeInterval:(NSUInteger)maxKeyFrameInterval error:(NSError **)error
{
	return [self setValue:@(maxKeyFrameInterval) forProperty:(__bridge NSString *)kVTCompressionPropertyKey_MaxKeyFrameInterval  error:error];
}

- (NSTimeInterval)maxKeyframeIntervalDuration
{
	NSNumber *value = [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration error:nil];
	return value.doubleValue;
}

- (BOOL)setMaxKeyframeIntervalDuration:(NSTimeInterval)maxKeyFrameIntervalDuration error:(NSError **)error
{
	return [self setValue:@(maxKeyFrameIntervalDuration) forProperty:(__bridge NSString *)kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration error:error];
}

- (BOOL)allowTemporalCompression
{
	NSNumber *value = [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_AllowTemporalCompression error:nil];
	return value.boolValue;
}

- (BOOL)setAllowTemporalCompression:(BOOL)allowTemporalCompression error:(NSError **)error
{
	return [self setValue:@(allowTemporalCompression) forProperty:(__bridge NSString *)kVTCompressionPropertyKey_AllowTemporalCompression error:error];
}

- (BOOL)allowFrameReordering
{
	NSNumber *value = [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_AllowFrameReordering error:nil];
	return value.boolValue;
}

- (BOOL)setAllowFrameReordering:(BOOL)allowFrameReordering error:(NSError **)error
{
	return [self setValue:@(allowFrameReordering) forProperty:(__bridge NSString *)kVTCompressionPropertyKey_AllowFrameReordering error:error];
}

- (SInt32)averageBitrate
{
	NSNumber *value = [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_AverageBitRate error:nil];
	return value.intValue;
}

- (BOOL)setAverageBitrate:(SInt32)averageBitrate error:(NSError **)error
{
	return [self setValue:@(averageBitrate) forProperty:(__bridge NSString *)kVTCompressionPropertyKey_AverageBitRate error:error];
}

- (NSArray *)dataRateLimits
{
	return [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_DataRateLimits error:nil];
}

- (BOOL)setDataRateLimits:(NSArray *)dataRateLimits error:(NSError **)error
{
	return [self setValue:dataRateLimits forProperty:(__bridge NSString *)kVTCompressionPropertyKey_DataRateLimits error:error];
}

- (BOOL)setConstantBitrate:(SInt32)constantBitrate forInterval:(NSTimeInterval)interval error:(NSError **)error
{
	NSArray *dataRateLimits = @[ @(constantBitrate), @(interval) ];
	return [self setDataRateLimits:dataRateLimits error:error];
}

- (BOOL)setConstantBitrate:(SInt32)constantBitrate error:(NSError **)error
{
	return [self setConstantBitrate:constantBitrate forInterval:1.0 error:error];
}



- (float)quality;
{
	NSNumber *value = [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_Quality error:nil];
	return value.floatValue;
}

- (BOOL)setQuality:(float)quality error:(NSError **)error;
{
	return [self setValue:@(quality) forProperty:(__bridge NSString *)kVTCompressionPropertyKey_Quality error:error];
}

- (NSString *)profileLevel
{
	return [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_ProfileLevel error:nil];
}

- (BOOL)setProfileLevel:(NSString *)profileLevel error:(NSError **)error
{
	return [self setValue:profileLevel forProperty:(__bridge NSString *)kVTCompressionPropertyKey_ProfileLevel error:error];
}

- (NSString *)H264EntropyMode
{
	return [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_H264EntropyMode error:nil];
}

- (BOOL)setH264EntropyMode:(NSString *)H264EntropyMode error:(NSError **)error
{
	return [self setValue:H264EntropyMode forProperty:(__bridge NSString *)kVTCompressionPropertyKey_H264EntropyMode error:error];
}

- (BOOL)realtime
{
	NSNumber *value = [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_RealTime error:nil];
	return value.boolValue;
}

- (BOOL)setRealtime:(BOOL)realtime error:(NSError **)error
{
	return [self setValue:@(realtime) forProperty:(__bridge NSString *)kVTCompressionPropertyKey_RealTime error:nil];
}

//- (BOOL)usingHardwareAcceleratedVideoEncoder
//{
//	NSNumber *value = [self valueForProperty:(__bridge NSString *)kVTCompressionPropertyKey_UsingHardwareAcceleratedVideoEncoder error:nil];
//	return value.boolValue;
//}

@end
