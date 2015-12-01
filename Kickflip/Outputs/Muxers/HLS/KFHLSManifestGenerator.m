//
//  KFHLSManifestGenerator.m
//  Kickflip
//
//  Created by Christopher Ballinger on 10/1/13.
//  Copyright (c) 2013 OpenWatch, Inc. All rights reserved.
//

#import "KFHLSManifestGenerator.h"
#import "KFLog.h"

@interface KFHLSManifestGenerator()
@property (nonatomic, strong) NSMutableDictionary *segments;
@property (nonatomic) BOOL finished;
@end

@implementation KFHLSManifestGenerator

- (NSMutableString*) header {
    NSMutableString *header = [NSMutableString stringWithFormat:@"#EXTM3U\n#EXT-X-VERSION:%lu\n#EXT-X-TARGETDURATION:%g\n", (unsigned long)self.version, self.targetDuration];
    NSString *type = nil;
    if (self.playlistType == KFHLSManifestPlaylistTypeVOD) {
        type = @"VOD";
    } else if (self.playlistType == KFHLSManifestPlaylistTypeEvent) {
        type = @"EVENT";
    }
    if (type) {
        [header appendFormat:@"#EXT-X-PLAYLIST-TYPE:%@\n", type];
    }
    [header appendFormat:@"#EXT-X-MEDIA-SEQUENCE:%ld\n", (long)self.mediaSequence];
    return header;
}

- (NSString*) footer {
    return @"#EXT-X-ENDLIST\n";
}

- (id) initWithTargetDuration:(float)targetDuration playlistType:(KFHLSManifestPlaylistType)playlistType {
    if (self = [super init]) {
        self.targetDuration = targetDuration;
        self.playlistType = playlistType;
        self.version = 3;
        self.mediaSequence = -1;
        self.segments = [NSMutableDictionary new];
        self.finished = NO;
    }
    return self;
}

- (void) appendFileName:(NSString *)fileName duration:(float)duration mediaSequence:(NSUInteger)mediaSequence {
    if (mediaSequence > self.mediaSequence) {
        self.mediaSequence = mediaSequence;
    }
    
    if (duration > self.targetDuration) {
        self.targetDuration = duration;
    }
    
    if ([self.segments objectForKey:[NSNumber numberWithInteger:mediaSequence]] == nil) {
        DDLogDebug(@"%@", [NSString stringWithFormat:@"Writing to manifest... #EXTINF:%g %@", duration, fileName]);
        [self.segments setObject:[NSString stringWithFormat:@"#EXTINF:%g,\n%@\n", duration, fileName] forKey:[NSNumber numberWithInteger:mediaSequence]];
    }
}

- (void) finalizeManifest {
    self.finished = YES;
    self.mediaSequence = 0;
}

- (NSString*) stripToNumbers:(NSString*)string {
    return [[string componentsSeparatedByCharactersInSet:
             [[NSCharacterSet decimalDigitCharacterSet] invertedSet]]
            componentsJoinedByString:@""];
}

- (void) appendFromLiveManifest:(NSString *)liveManifest {
    NSArray *rawLines = [liveManifest componentsSeparatedByString:@"\n"];
    NSMutableArray *lines = [NSMutableArray arrayWithCapacity:rawLines.count];
    
    NSUInteger index = 0;
    for (NSString *line in rawLines) {
        if ([line rangeOfString:@"#EXTINF:"].location != NSNotFound) {
            NSString *extInf = line;
            NSString *extInfNumberString = [self stripToNumbers:extInf];
            NSString *segmentName = rawLines[index+1];
            NSString *segmentNumberString = [self stripToNumbers:segmentName];
            float duration = [extInfNumberString floatValue];
            NSInteger sequence = [segmentNumberString integerValue];
            [self appendFileName:segmentName duration:duration mediaSequence:sequence];
        }
        index++;
    }
}


- (NSString *) masterString {
    int videoWidth;
    int videoHeight;
    
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        videoWidth = [Kickflip resolutionHeight];
        videoHeight = [Kickflip resolutionWidth];
    } else {
        videoWidth = [Kickflip resolutionWidth];
        videoHeight = [Kickflip resolutionHeight];
    }
    
    return [NSString stringWithFormat:@"#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=556000,CODECS=\"avc1.77.21,mp4a.40.2\",RESOLUTION=%dx%d\n%@.m3u8",
                videoWidth,
                videoHeight,
                (self.finished ? @"vod" : @"index")];
}

- (NSString *) manifestString {
    NSMutableString *manifest = [self header];
    
    NSArray *sortedKeys = [[self.segments allKeys] sortedArrayUsingSelector:@selector(compare:)];
    for (NSNumber *key in sortedKeys) {
        [manifest appendString:[self.segments objectForKey:key]];
    }
    
    [manifest appendString:[self footer]];
    
    DDLogVerbose(@"Latest manifest:\n%@", manifest);
    
    return manifest;
}

@end
