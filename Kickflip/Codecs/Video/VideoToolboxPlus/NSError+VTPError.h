#import <Foundation/Foundation.h>

extern NSString * const VTPErrorDomain;


@interface NSError (VTPError)

+ (instancetype)videoToolboxErrorWithStatus:(OSStatus)status;

@end
