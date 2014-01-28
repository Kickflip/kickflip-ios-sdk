//
//  RTSPMessage.h
//  Encoder Demo
//
//  Created by Geraint Davies on 24/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import <Foundation/Foundation.h>

@interface RTSPMessage : NSObject


+ (RTSPMessage*) createWithData:(CFDataRef) data;

- (NSString*) valueForOption:(NSString*) option;
- (NSString*) createResponse:(int) code text:(NSString*) desc;

@property NSString* command;
@property int sequence;

@end
