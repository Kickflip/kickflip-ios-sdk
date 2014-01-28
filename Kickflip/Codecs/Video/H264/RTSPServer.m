//
//  RTSPServer.m
//  Encoder Demo
//
//  Created by Geraint Davies on 17/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "RTSPServer.h"
#import "RTSPClientConnection.h"
#import "ifaddrs.h"
#import "arpa/inet.h"

@interface RTSPServer ()

{
    CFSocketRef _listener;
    NSMutableArray* _connections;
    NSData* _configData;
    int _bitrate;
}

- (RTSPServer*) init:(NSData*) configData;
- (void) onAccept:(CFSocketNativeHandle) childHandle;

@end

static void onSocket (
                 CFSocketRef s,
                 CFSocketCallBackType callbackType,
                 CFDataRef address,
                 const void *data,
                 void *info
                 )
{
    RTSPServer* server = (__bridge RTSPServer*)info;
    switch (callbackType)
    {
        case kCFSocketAcceptCallBack:
        {
            CFSocketNativeHandle* pH = (CFSocketNativeHandle*) data;
            [server onAccept:*pH];
            break;
        }
        default:
            NSLog(@"unexpected socket event");
            break;
    }
    
}

@implementation RTSPServer

@synthesize bitrate = _bitrate;

+ (RTSPServer*) setupListener:(NSData*) configData
{
    RTSPServer* obj = [RTSPServer alloc];
    if (![obj init:configData])
    {
        return nil;
    }
    return obj;
}

- (RTSPServer*) init:(NSData*) configData
{
    _configData = configData;
    _connections = [NSMutableArray arrayWithCapacity:10];
    
    CFSocketContext info;
    memset(&info, 0, sizeof(info));
    info.info = (void*)CFBridgingRetain(self);
    
    _listener = CFSocketCreate(nil, PF_INET, SOCK_STREAM, IPPROTO_TCP, kCFSocketAcceptCallBack, onSocket, &info);
    
    // must set SO_REUSEADDR in case a client is still holding this address
    int t = 1;
    setsockopt(CFSocketGetNative(_listener), SOL_SOCKET, SO_REUSEADDR, &t, sizeof(t));
    
    struct sockaddr_in addr;
    addr.sin_addr.s_addr = INADDR_ANY;
    addr.sin_family = AF_INET;
    addr.sin_port = htons(554);
    CFDataRef dataAddr = CFDataCreate(nil, (const uint8_t*)&addr, sizeof(addr));
    CFSocketError e = CFSocketSetAddress(_listener, dataAddr);
    CFRelease(dataAddr);
    
    if (e)
    {
        NSLog(@"bind error %d", (int) e);
    }
    
    CFRunLoopSourceRef rls = CFSocketCreateRunLoopSource(nil, _listener, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), rls, kCFRunLoopCommonModes);
    CFRelease(rls);
    
    return self;
}

- (NSData*) getConfigData
{
    return _configData;
}

- (void) onAccept:(CFSocketNativeHandle) childHandle
{
    RTSPClientConnection* conn = [RTSPClientConnection createWithSocket:childHandle server:self];
    if (conn != nil)
    {
        @synchronized(self)
        {
            NSLog(@"Client connected");
            [_connections addObject:conn];
        }
    }
    
}

- (void) onVideoData:(NSArray*) data time:(double) pts
{
    @synchronized(self)
    {
        for (RTSPClientConnection* conn in _connections)
        {
            [conn onVideoData:data time:pts];
        }
    }
}

- (void) shutdownConnection:(id)conn
{
    @synchronized(self)
    {
        NSLog(@"Client disconnected");
        [_connections removeObject:conn];
    }
}

- (void) shutdownServer
{
    @synchronized(self)
    {
        for (RTSPClientConnection* conn in _connections)
        {
            [conn shutdown];
        }
        _connections = [NSMutableArray arrayWithCapacity:10];
        if (_listener != nil)
        {
            CFSocketInvalidate(_listener);
            _listener = nil;
        }
    }
}

+ (NSString*) getIPAddress
{
    NSString* address;
    struct ifaddrs *interfaces = nil;
    
    // get all our interfaces and find the one that corresponds to wifi
    if (!getifaddrs(&interfaces))
    {
        for (struct ifaddrs* addr = interfaces; addr != NULL; addr = addr->ifa_next)
        {
            if (([[NSString stringWithUTF8String:addr->ifa_name] isEqualToString:@"en0"]) &&
                (addr->ifa_addr->sa_family == AF_INET))
            {
                struct sockaddr_in* sa = (struct sockaddr_in*) addr->ifa_addr;
                address = [NSString stringWithUTF8String:inet_ntoa(sa->sin_addr)];
                break;
            }
        }
    }
    freeifaddrs(interfaces);
    return address;
}

@end
