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
@property (nonatomic, strong) NSMutableString *segmentsString;
@property (nonatomic) BOOL finished;
@end

@implementation KFHLSManifestGenerator

- (NSMutableString*) header {
    NSMutableString *header = [NSMutableString stringWithFormat:@"#EXTM3U\n#EXT-X-VERSION:%d\n#EXT-X-TARGETDURATION:%g\n", self.version, self.targetDuration];
    NSString *type = nil;
    if (self.playlistType == KFHLSManifestPlaylistTypeVOD) {
        type = @"VOD";
    } else if (self.playlistType == KFHLSManifestPlaylistTypeEvent) {
        type = @"EVENT";
    }
    if (type) {
        [header appendFormat:@"#EXT-X-PLAYLIST-TYPE:%@\n", type];
    }
    [header appendFormat:@"#EXT-X-MEDIA-SEQUENCE:%d\n", self.mediaSequence];
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
        self.segmentsString = [NSMutableString string];
        self.finished = NO;
    }
    return self;
}

- (void) appendFileName:(NSString *)fileName duration:(float)duration mediaSequence:(NSUInteger)mediaSequence {
    if (self.finished) {
        return;
    }
    self.mediaSequence = mediaSequence;
    if (duration > self.targetDuration) {
        self.targetDuration = duration;
    }
    [self.segmentsString appendFormat:@"#EXTINF:%g,\n%@\n", duration, fileName];
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
    NSArray *lines = [liveManifest componentsSeparatedByString:@"\n"];
    if (lines.count < 6) {
        return;
    }
    NSString *extInf = lines[lines.count-3];
    NSString *extInfNumberString = [self stripToNumbers:extInf];
    NSString *segmentName = lines[lines.count-2];
    NSString *segmentNumberString = [self stripToNumbers:segmentName];
    float duration = [extInfNumberString floatValue];
    NSInteger sequence = [segmentNumberString integerValue];
    if (sequence > self.mediaSequence) {
        [self appendFileName:segmentName duration:duration mediaSequence:sequence];
    }
}

- (NSString*) manifestString {
    NSMutableString *manifest = [self header];
    [manifest appendString:self.segmentsString];
    if (self.finished) {
        [manifest appendString:[self footer]];
    }
    DDLogInfo(@"Latest manifest:\n%@", manifest);
    return manifest;
}

@end
