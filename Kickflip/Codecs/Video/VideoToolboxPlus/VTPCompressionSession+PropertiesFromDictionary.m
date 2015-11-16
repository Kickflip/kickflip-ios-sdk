#import "VTPCompressionSession+PropertiesFromDictionary.h"


@implementation VTPCompressionSession (PropertiesFromDictionary)

- (void)setPropertiesFromDictionary:(NSDictionary *)dictionary error:(NSError **)error
{
	[dictionary enumerateKeysAndObjectsUsingBlock:^(id property, id value, BOOL *stop) {
		[self setValue:value forProperty:property error:error];
	}];
}

@end
