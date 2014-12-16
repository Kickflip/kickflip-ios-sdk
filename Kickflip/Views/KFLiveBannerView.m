//
//  KFLiveBannerView.m
//  Pods
//
//  Created by Christopher Ballinger on 4/10/14.
//
//

#import "KFLiveBannerView.h"
#import "PureLayout.h"

@implementation KFLiveBannerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor blackColor];
        [self setupRedDotView];
        [self setupLabel];
    }
    return self;
}

- (void) setupLabel {
    self.liveLabel = [[UILabel alloc] init];
    self.liveLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.liveLabel.textColor = [UIColor whiteColor];
    self.liveLabel.font = [UIFont fontWithName:@"HelveticaNeue-MediumItalic" size:17.0f];
    self.liveLabel.text = NSLocalizedString(@"LIVE", @"label indicating that a live recording is in progress");
    [self addSubview:self.liveLabel];
    [self.liveLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.liveLabel autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.redDotView withOffset:5.0f];
}

// http://stackoverflow.com/a/15096496/805882
- (void) setupRedDotView {
    self.redDotView = [[UIView alloc] init];
    self.redDotView.translatesAutoresizingMaskIntoConstraints = NO;
    CGFloat diameter = 15.0f;
    CGFloat padding = 5.0f;
    
    CAShapeLayer *circleLayer = [CAShapeLayer layer];
    // Give the layer the same bounds as your image view
    [circleLayer setBounds:CGRectMake(0.0f, 0.0f, [self.redDotView bounds].size.width,
                                      [self.redDotView bounds].size.height)];
    // Position the circle anywhere you like, but this will center it
    // In the parent layer, which will be your image view's root layer
    [circleLayer setPosition:CGPointMake([self.redDotView bounds].size.width/2.0f,
                                         [self.redDotView bounds].size.height/2.0f)];
    // Create a circle path.
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:
                          CGRectMake(0.0f, 0.0f, diameter,diameter)];
    // Set the path on the layer
    circleLayer.path = path.CGPath;
    // Set the stroke color
    circleLayer.fillColor = UIColor.redColor.CGColor;
    // Set the stroke line width
    
    // Add the sublayer to the image view's layer tree
    [[self.redDotView layer] addSublayer:circleLayer];
    
    [self addSubview:self.redDotView];
    [self.redDotView autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:padding];
    [self.redDotView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
    [self.redDotView autoSetDimensionsToSize:CGSizeMake(diameter, diameter)];
}

- (CGSize) intrinsicContentSize {
    return CGSizeMake(70, 30);
}

@end
