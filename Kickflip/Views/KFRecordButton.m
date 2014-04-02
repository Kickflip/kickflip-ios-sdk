//
//  KFRecordButton.m
//  Pods
//
//  Created by Christopher Ballinger on 4/2/14.
//
//

#import "KFRecordButton.h"

@interface KFRecordButton()
@property (nonatomic, strong) UIImage *startImage;
@property (nonatomic, strong) UIImage *stopImage;
@property (nonatomic, strong) UIImageView *outerImageView;
@end

@implementation KFRecordButton

- (instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        UIImage *image = [UIImage imageNamed:@"KFRecordButtonStart"];
        self.startImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [self setImage:self.startImage
                     forState:UIControlStateNormal];
        
        image = [UIImage imageNamed:@"KFRecordButtonStop"];
        self.stopImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        self.tintColor = [UIColor redColor];
        self.outerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"KFRecordButtonBorder"]];
        [self addSubview:self.outerImageView];
        self.frame = CGRectMake(0, 0, 66, 66);
        self.outerImageView.frame = self.frame;
    }
    return self;
}

- (void) setIsRecording:(BOOL)isRecording {
    _isRecording = isRecording;
    if (_isRecording) {
        [self setImage:self.stopImage
              forState:UIControlStateNormal];
    } else {
        [self setImage:self.startImage
              forState:UIControlStateNormal];
    }
}

- (void) setFrame:(CGRect)frame {
    CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, 66, 66);
    [super setFrame:newFrame];
}

@end
