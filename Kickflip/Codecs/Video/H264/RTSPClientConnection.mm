//
//  RTSPClientConnection.m
//  Encoder Demo
//
//  Created by Geraint Davies on 24/01/2013.
//  Copyright (c) 2013 GDCL http://www.gdcl.co.uk/license.htm
//

#import "RTSPClientConnection.h"
#import "RTSPMessage.h"
#import "NALUnit.h"
#import "arpa/inet.h"

void tonet_short(uint8_t* p, unsigned short s)
{
    p[0] = (s >> 8) & 0xff;
    p[1] = s & 0xff;
}
void tonet_long(uint8_t* p, unsigned long l)
{
    p[0] = (l >> 24) & 0xff;
    p[1] = (l >> 16) & 0xff;
    p[2] = (l >> 8) & 0xff;
    p[3] = l & 0xff;
}

static const char* Base64Mapping = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
static const int max_packet_size = 1200;

NSString* encodeLong(unsigned long val, int nPad)
{
    char ch[4];
    int cch = 4 - nPad;
    for (int i = 0; i < cch; i++)
    {
        int shift = 6 * (cch - (i+1));
        int bits = (val >> shift) & 0x3f;
        ch[i] = Base64Mapping[bits];
    }
    for (int i = 0; i < nPad; i++)
    {
        ch[cch + i] = '=';
    }
    NSString* s = [[NSString alloc] initWithBytes:ch length:4 encoding:NSUTF8StringEncoding];
    return s;
}

NSString* encodeToBase64(NSData* data)
{
    NSString* s = @"";
    
    const uint8_t* p = (const uint8_t*) [data bytes];
    int cBytes = [data length];
    while (cBytes >= 3)
    {
        unsigned long val = (p[0] << 16) + (p[1] << 8) + p[2];
        p += 3;
        cBytes -= 3;
        
        s = [s stringByAppendingString:encodeLong(val, 0)];
    }
    if (cBytes > 0)
    {
        int nPad;
        unsigned long val;
        if (cBytes == 1)
        {
            // pad 8 bits to 2 x 6 and add 2 ==
            nPad = 2;
            val = p[0] << 4;
        }
        else
        {
            // must be two bytes -- pad 16 bits to 3 x 6 and add one =
            nPad = 1;
            val = (p[0] << 8) + p[1];
            val = val << 2;
        }
        s = [s stringByAppendingString:encodeLong(val, nPad)];
    }
    return s;
}

enum ServerState
{
    ServerIdle,
    Setup,
    Playing,
};

@interface RTSPClientConnection ()
{
    CFSocketRef _s;
    RTSPServer* _server;
    CFRunLoopSourceRef _rls;
    
    CFDataRef _addrRTP;
    CFSocketRef _sRTP;
    CFDataRef _addrRTCP;
    CFSocketRef _sRTCP;
    NSString* _session;
    ServerState _state;
    long _packets;
    long _bytesSent;
    long _ssrc;
    BOOL _bFirst;
    
    // time mapping using NTP
    uint64_t _ntpBase;
    uint64_t _rtpBase;
    double _ptsBase;

    // RTCP stats
    long _packetsReported;
    long _bytesReported;
    NSDate* _sentRTCP;
    
    // reader reports
    CFSocketRef _recvRTCP;
    CFRunLoopSourceRef _rlsRTCP;
}

- (RTSPClientConnection*) initWithSocket:(CFSocketNativeHandle) s Server:(RTSPServer*) server;
- (void) onSocketData:(CFDataRef)data;
- (void) onRTCP:(CFDataRef) data;

@end

static void onSocket (
               CFSocketRef s,
               CFSocketCallBackType callbackType,
               CFDataRef address,
               const void *data,
               void *info
               )
{
    RTSPClientConnection* conn = (__bridge RTSPClientConnection*)info;
    switch (callbackType)
    {
        case kCFSocketDataCallBack:
            [conn onSocketData:(CFDataRef) data];
            break;
            
        default:
            NSLog(@"unexpected socket event");
            break;
    }
    
}

static void onRTCP(CFSocketRef s,
                   CFSocketCallBackType callbackType,
                   CFDataRef address,
                   const void *data,
                   void *info
                   )
{
    RTSPClientConnection* conn = (__bridge RTSPClientConnection*)info;
    switch (callbackType)
    {
        case kCFSocketDataCallBack:
            [conn onRTCP:(CFDataRef) data];
            break;
            
        default:
            NSLog(@"unexpected socket event");
            break;
    }
}

@implementation RTSPClientConnection

+ (RTSPClientConnection*) createWithSocket:(CFSocketNativeHandle) s server:(RTSPServer*) server
{
    RTSPClientConnection* conn = [RTSPClientConnection alloc];
    if ([conn initWithSocket:s Server:server] != nil)
    {
        return conn;
    }
    return nil;
}

- (RTSPClientConnection*) initWithSocket:(CFSocketNativeHandle)s Server:(RTSPServer *)server
{
    _state = ServerIdle;
    _server = server;
    CFSocketContext info;
    memset(&info, 0, sizeof(info));
    info.info = (void*)CFBridgingRetain(self);
    
    _s = CFSocketCreateWithNative(nil, s, kCFSocketDataCallBack, onSocket, &info);
    
    _rls = CFSocketCreateRunLoopSource(nil, _s, 0);
    CFRunLoopAddSource(CFRunLoopGetMain(), _rls, kCFRunLoopCommonModes);

    return self;
}

- (void) onSocketData:(CFDataRef)data
{
    if (CFDataGetLength(data) == 0)
    {
        [self tearDown];
        CFSocketInvalidate(_s);
        _s = nil;
        [_server shutdownConnection:self];
        return;
    }
    RTSPMessage* msg = [RTSPMessage createWithData:data];
    if (msg != nil)
    {
        NSString* response = nil;
        NSString* cmd = msg.command;
        if ([cmd caseInsensitiveCompare:@"options"] == NSOrderedSame)
        {
            response = [msg createResponse:200 text:@"OK"];
            response = [response stringByAppendingString:@"Server: AVEncoderDemo/1.0\r\n"];
            response = [response stringByAppendingString:@"Public: DESCRIBE, SETUP, TEARDOWN, PLAY, OPTIONS\r\n\r\n"];
        }
        else if ([cmd caseInsensitiveCompare:@"describe"] == NSOrderedSame)
        {
            NSString* sdp = [self makeSDP];
            response = [msg createResponse:200 text:@"OK"];
            NSString* date = [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterLongStyle timeStyle:NSDateFormatterLongStyle];
            CFDataRef dlocaladdr = CFSocketCopyAddress(_s);
            struct sockaddr_in* localaddr = (struct sockaddr_in*) CFDataGetBytePtr(dlocaladdr);
            
            response = [response stringByAppendingFormat:@"Content-base: rtsp://%s/\r\n", inet_ntoa(localaddr->sin_addr)];
            CFRelease(dlocaladdr);
            response = [response stringByAppendingFormat:@"Date: %@\r\nContent-Type: application/sdp\r\nContent-Length: %d\r\n\r\n", date, [sdp length] ];
            response = [response stringByAppendingString:sdp];
        }
        else if ([cmd caseInsensitiveCompare:@"setup"] == NSOrderedSame)
        {
            NSString* transport = [msg valueForOption:@"transport"];
            NSArray* props = [transport componentsSeparatedByString:@";"];
            NSArray* ports = nil;
            for (NSString* s in props)
            {
                if ([s length] > 14)
                {
                    if ([s compare:@"client-port=" options:0 range:NSMakeRange(0, 12)])
                    {
                        NSString* val = [s substringFromIndex:12];
                        ports = [val componentsSeparatedByString:@"-"];
                        break;
                    }
                }
            }
            if ([ports count] == 2)
            {
                int portRTP = [ports[0] integerValue];
                int portRTCP = [ports[1] integerValue];
                
                NSString* session_name = [self createSession:portRTP rtcp:portRTCP];
                if (session_name != nil)
                {
                    response = [msg createResponse:200 text:@"OK"];
                    response = [response stringByAppendingFormat:@"Session: %@\r\nTransport: RTP/AVP;unicast;client_port=%d-%d;server_port=6970-6971\r\n\r\n",
                                session_name,
                                portRTP,portRTCP];
                }
            }
            if (response == nil)
            {
                // !!
                response = [msg createResponse:451 text:@"Need better error string here"];
            }
        }
        else if ([cmd caseInsensitiveCompare:@"play"] == NSOrderedSame)
        {
            @synchronized(self)
            {
                if (_state != Setup)
                {
                    response = [msg createResponse:451 text:@"Wrong state"];
                }
                else
                {
                    _state = Playing;
                    _bFirst = YES;
                    response = [msg createResponse:200 text:@"OK"];
                    response = [response stringByAppendingFormat:@"Session: %@\r\n\r\n", _session];
                }
            }
        }
        else if ([cmd caseInsensitiveCompare:@"teardown"] == NSOrderedSame)
        {
            [self tearDown];
            response = [msg createResponse:200 text:@"OK"];
        }
        else
        {
            NSLog(@"RTSP method %@ not handled", cmd);
            response = [msg createResponse:451 text:@"Method not recognised"];
        }
        if (response != nil)
        {
            NSData* dataResponse = [response dataUsingEncoding:NSUTF8StringEncoding];
            CFSocketError e = CFSocketSendData(_s, NULL, (__bridge CFDataRef)(dataResponse), 2);
            if (e)
            {
                NSLog(@"send %ld", e);
            }
        }
    }
}

- (NSString*) makeSDP
{
    NSData* config = [_server getConfigData];
    
    avcCHeader avcC((const BYTE*)[config bytes], [config length]);
    SeqParamSet seqParams;
    seqParams.Parse(avcC.sps());
    int cx = seqParams.EncodedWidth();
    int cy = seqParams.EncodedHeight();
    
    NSString* profile_level_id = [NSString stringWithFormat:@"%02x%02x%02x", seqParams.Profile(), seqParams.Compat(), seqParams.Level()];
    
    NSData* data = [NSData dataWithBytes:avcC.sps()->Start() length:avcC.sps()->Length()];
    NSString* sps = encodeToBase64(data);
    data = [NSData dataWithBytes:avcC.pps()->Start() length:avcC.pps()->Length()];
    NSString* pps = encodeToBase64(data);
    
    // !! o=, s=, u=, c=, b=? control for track?
    unsigned long verid = random();
    
    CFDataRef dlocaladdr = CFSocketCopyAddress(_s);
    struct sockaddr_in* localaddr = (struct sockaddr_in*) CFDataGetBytePtr(dlocaladdr);
    NSString* sdp = [NSString stringWithFormat:@"v=0\r\no=- %ld %ld IN IP4 %s\r\ns=Live stream from iOS\r\nc=IN IP4 0.0.0.0\r\nt=0 0\r\na=control:*\r\n", verid, verid, inet_ntoa(localaddr->sin_addr)];
    CFRelease(dlocaladdr);
    
    int packets = (_server.bitrate / (max_packet_size * 8)) + 1;
    
    sdp = [sdp stringByAppendingFormat:@"m=video 0 RTP/AVP 96\r\nb=TIAS:%d\r\na=maxprate:%d.0000\r\na=control:streamid=1\r\n", _server.bitrate, packets];
    sdp = [sdp stringByAppendingFormat:@"a=rtpmap:96 H264/90000\r\na=mimetype:string;\"video/H264\"\r\na=framesize:96 %d-%d\r\na=Width:integer;%d\r\na=Height:integer;%di\r\n", cx, cy, cx, cy];
    sdp = [sdp stringByAppendingFormat:@"a=fmtp:96 packetization-mode=1;profile-level-id=%@;sprop-parameter-sets=%@,%@\r\n", profile_level_id, sps, pps];
    return sdp;
}

- (NSString*) createSession:(int) portRTP rtcp:(int) portRTCP
{
    // !! most basic possible for initial testing
    @synchronized(self)
    {
        CFDataRef data = CFSocketCopyPeerAddress(_s);
        struct sockaddr_in* paddr = (struct sockaddr_in*) CFDataGetBytePtr(data);
        paddr->sin_port = htons(portRTP);
        _addrRTP = CFDataCreate(nil, (uint8_t*) paddr, sizeof(struct sockaddr_in));
        _sRTP = CFSocketCreate(nil, PF_INET, SOCK_DGRAM, IPPROTO_UDP, 0, nil, nil);
        
        paddr->sin_port = htons(portRTCP);
        _addrRTCP = CFDataCreate(nil, (uint8_t*) paddr, sizeof(struct sockaddr_in));
        _sRTCP = CFSocketCreate(nil, PF_INET, SOCK_DGRAM, IPPROTO_UDP, 0, nil, nil);
        CFRelease(data);
        
        // reader reports received here
        CFSocketContext info;
        memset(&info, 0, sizeof(info));
        info.info = (void*)CFBridgingRetain(self);
        _recvRTCP = CFSocketCreate(nil, PF_INET, SOCK_DGRAM, IPPROTO_UDP, kCFSocketDataCallBack, onRTCP, &info);
        
        struct sockaddr_in addr;
        addr.sin_addr.s_addr = INADDR_ANY;
        addr.sin_family = AF_INET;
        addr.sin_port = htons(6971);
        CFDataRef dataAddr = CFDataCreate(nil, (const uint8_t*)&addr, sizeof(addr));
        CFSocketSetAddress(_recvRTCP, dataAddr);
        CFRelease(dataAddr);
        
        _rlsRTCP = CFSocketCreateRunLoopSource(nil, _recvRTCP, 0);
        CFRunLoopAddSource(CFRunLoopGetMain(), _rlsRTCP, kCFRunLoopCommonModes);
        
        // flag that setup is valid
        long sessionid = random();
        _session = [NSString stringWithFormat:@"%ld", sessionid];
        _state = Setup;
        _ssrc = random();
        _packets = 0;
        _bytesSent = 0;
        _rtpBase = 0;
    
        _sentRTCP = nil;
        _packetsReported = 0;
        _bytesReported = 0;
    }
    return _session;
}

- (void) onVideoData:(NSArray*) data time:(double) pts
{
    @synchronized(self)
    {
        if (_state != Playing)
        {
            return;
        }
    }
    
    const int rtp_header_size = 12;
    const int max_single_packet = max_packet_size - rtp_header_size;
    const int max_fragment_packet = max_single_packet - 2;
    unsigned char packet[max_packet_size];
    
    int nNALUs = [data count];
    for (int i = 0; i < nNALUs; i++)
    {
        NSData* nalu = [data objectAtIndex:i];
        int cBytes = [nalu length];
        BOOL bLast = (i == nNALUs-1);
        
        const unsigned char* pSource = (unsigned char*)[nalu bytes];
 
        if (_bFirst)
        {
            if ((pSource[0] & 0x1f) != 5)
            {
                continue;
            }
            _bFirst = NO;
            NSLog(@"Playback starting at first IDR");
        }
        
        if (cBytes < max_single_packet)
        {
            [self writeHeader:packet marker:bLast time:pts];
            memcpy(packet + rtp_header_size, [nalu bytes], cBytes);
            [self sendPacket:packet length:(cBytes + rtp_header_size)];
        }
        else
        {
            unsigned char NALU_Header = pSource[0];
            pSource += 1;
            cBytes -= 1;
            BOOL bStart = YES;
            
            while (cBytes)
            {
                int cThis = (cBytes < max_fragment_packet)? cBytes : max_fragment_packet;
                BOOL bEnd = (cThis == cBytes);
                [self writeHeader:packet marker:(bLast && bEnd) time:pts];
                unsigned char* pDest = packet + rtp_header_size;
                
                pDest[0] = (NALU_Header & 0xe0) + 28;   // FU_A type
                unsigned char fu_header = (NALU_Header & 0x1f);
                if (bStart)
                {
                    fu_header |= 0x80;
                    bStart = false;
                }
                else if (bEnd)
                {
                    fu_header |= 0x40;
                }
                pDest[1] = fu_header;
                pDest += 2;
                memcpy(pDest, pSource, cThis);
                pDest += cThis;
                [self sendPacket:packet length:(pDest - packet)];
                
                pSource += cThis;
                cBytes -= cThis;
            }
        }
    }
}

- (void) writeHeader:(uint8_t*) packet marker:(BOOL) bMarker time:(double) pts
{
    packet[0] = 0x80;   // v= 2
    if (bMarker)
    {
        packet[1] = 96 | 0x80;
    }
    else
    {
        packet[1] = 96;
    }
    unsigned short seq = _packets & 0xffff;
    tonet_short(packet+2, seq);

    // map time
    while (_rtpBase == 0)
    {
        _rtpBase = random();
        _ptsBase = pts;
        NSDate* now = [NSDate date];
        // ntp is based on 1900. There's a known fixed offset from 1900 to 1970.
        NSDate* ref = [NSDate dateWithTimeIntervalSince1970:-2208988800L];
        double interval = [now timeIntervalSinceDate:ref];
        _ntpBase = (uint64_t)(interval * (1LL << 32));
    }
    pts -= _ptsBase;
    uint64_t rtp = (uint64_t)(pts * 90000);
    rtp += _rtpBase;
    tonet_long(packet + 4, rtp);
    tonet_long(packet + 8, _ssrc);
}

- (void) sendPacket:(uint8_t*) packet length:(int) cBytes
{
    @synchronized(self)
    {
        if (_sRTP)
        {
            CFDataRef data = CFDataCreate(nil, packet, cBytes);
            CFSocketSendData(_sRTP, _addrRTP, data, 0);
            CFRelease(data);
        }
        _packets++;
        _bytesSent += cBytes;
        
        // RTCP packets
        NSDate* now = [NSDate date];
        if ((_sentRTCP == nil) || ([now timeIntervalSinceDate:_sentRTCP] >= 1))
        {
            uint8_t buf[7 * sizeof(uint32_t)];
            buf[0] = 0x80;
            buf[1] = 200;   // type == SR
            tonet_short(buf+2, 6);  // length (count of uint32_t minus 1)
            tonet_long(buf+4, _ssrc);
            tonet_long(buf+8, (_ntpBase >> 32));
            tonet_long(buf+12, _ntpBase);
            tonet_long(buf+16, _rtpBase);
            tonet_long(buf+20, (_packets - _packetsReported));
            tonet_long(buf+24, (_bytesSent - _bytesReported));
            int lenRTCP = 28;
            if (_sRTCP)
            {
                CFDataRef dataRTCP = CFDataCreate(nil, buf, lenRTCP);
                CFSocketSendData(_sRTCP, _addrRTCP, dataRTCP, lenRTCP);
                CFRelease(dataRTCP);
            }
            
            _sentRTCP = now;
            _packetsReported = _packets;
            _bytesReported = _bytesSent;
        }
    }
}

- (void) onRTCP:(CFDataRef) data
{
    // NSLog(@"RTCP recv");
}

- (void) tearDown
{
    @synchronized(self)
    {
        if (_sRTP)
        {
            CFSocketInvalidate(_sRTP);
            _sRTP = nil;
        }
        if (_sRTCP)
        {
            CFSocketInvalidate(_sRTCP);
            _sRTCP = nil;
        }
        if (_recvRTCP)
        {
            CFSocketInvalidate(_recvRTCP);
            _recvRTCP = nil;
        }
        _session = nil;
    }
}

- (void) shutdown
{
    [self tearDown];
    @synchronized(self)
    {
        CFSocketInvalidate(_s);
        _s = nil;
    }
}
@end
