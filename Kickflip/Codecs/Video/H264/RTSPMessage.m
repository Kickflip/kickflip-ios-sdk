//
//  RTSPMessage.m
//  Encoder Demo
//
//  Created by Geraint Davies on 24/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "RTSPMessage.h"

@interface RTSPMessage ()

{
    NSArray* _lines;
    NSString* _request;
    int _cseq;
}

- (RTSPMessage*) initWithData:(CFDataRef) data;

@end

@implementation RTSPMessage

@synthesize command = _request;
@synthesize sequence = _cseq;

+ (RTSPMessage*) createWithData:(CFDataRef) data
{
    RTSPMessage* msg = [[RTSPMessage alloc] initWithData:data];
    return msg;
}

- (RTSPMessage*) initWithData:(CFDataRef) data
{
    self = [super init];
    NSString* msg = [[NSString alloc] initWithData:(__bridge NSData*)data encoding:NSUTF8StringEncoding];
    _lines = [msg componentsSeparatedByString:@"\r\n"];
    if ([_lines count] < 2)
    {
        NSLog(@"msg parse error");
        return nil;
    }
    NSArray* lineone = [[_lines objectAtIndex:0] componentsSeparatedByString:@" "];
    _request = [lineone objectAtIndex:0];
    NSString* strSeq = [self valueForOption:@"CSeq"];
    if (strSeq == nil)
    {
        NSLog(@"no cseq");
        return nil;
    }
    _cseq = [strSeq intValue];
    
    return self;
}

- (NSString*) valueForOption:(NSString*) option
{
    for (int i = 1; i < [_lines count]; i++)
    {
        NSString* line = [_lines objectAtIndex:i];
        NSArray* comps = [line componentsSeparatedByString:@":"];
        if ([comps count] == 2)
        {
            if ([option caseInsensitiveCompare:[comps objectAtIndex:0]] == NSOrderedSame)
            {
                NSString* val = [comps objectAtIndex:1];
                val = [val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                return val;
            }
        }
    }
    return nil;
}

- (NSString*) createResponse:(int) code text:(NSString*) desc
{
    NSString* val = [NSString stringWithFormat:@"RTSP/1.0 %d %@\r\nCSeq: %d\r\n", code, desc, self.sequence];
    return val;
}

@end
