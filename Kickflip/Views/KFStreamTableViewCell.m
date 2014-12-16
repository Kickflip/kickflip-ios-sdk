//
//  KFStreamTableViewCell.m
//  Pods
//
//  Created by Christopher Ballinger on 4/4/14.
//
//

#import "KFStreamTableViewCell.h"
#import "KFStream.h"
#import "PureLayout.h"
#import "KFDateUtils.h"
#import "UIImageView+WebCache.h"

static const NSUInteger kKFStreamTableViewCellLabelHeight = 20.0f;
static const NSUInteger kKFStreamTableViewCellPadding = 5.0f;

static NSString * const KFStreamTableViewCellIdentifier = @"KFStreamTableViewCellIdentifier";

@implementation KFStreamTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupThumbnailView];
        [self setupDateLabel];
        [self setupLocationLabel];
        [self setupDurationLabel];
        [self setupActionButton];
        [self setupLiveBannerView];
        [self setupLoadingActivityIndicatorView];
    }
    return self;
}

- (void) setupLiveBannerView {
    self.liveBannerView = [[KFLiveBannerView alloc] init];
    self.liveBannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.liveBannerView];
    [self.liveBannerView autoPinEdge:ALEdgeLeft toEdge:ALEdgeLeft ofView:self.thumbnailImageView];
    [self.liveBannerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.thumbnailImageView withOffset:20.0f];
}

- (void) setupLoadingActivityIndicatorView {
    self.loadingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.loadingIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.loadingIndicatorView];
    [self.loadingIndicatorView autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.thumbnailImageView];
    [self.loadingIndicatorView autoAlignAxis:ALAxisVertical toSameAxisOfView:self.thumbnailImageView];
}

- (void) setupDateLabel {
    self.dateLabel = [[UILabel alloc] init];
    self.dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f];
    [self.contentView addSubview:self.dateLabel];
    
    [self.dateLabel autoSetDimension:ALDimensionHeight toSize:kKFStreamTableViewCellLabelHeight];
    [self.dateLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thumbnailImageView withOffset:kKFStreamTableViewCellPadding];
    [self.dateLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:kKFStreamTableViewCellPadding];
}

- (void) setupActionButton {
    self.actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.actionButton.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *buttonImage = [UIImage imageNamed:@"KFStreamTableViewCellDots"];
    [self.actionButton setImage:buttonImage forState:UIControlStateNormal];
    [self.actionButton addTarget:self action:@selector(actionButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.actionButton];
    
    [self.actionButton autoSetDimensionsToSize:CGSizeMake(buttonImage.size.width, buttonImage.size.height + 10)];
    [self.actionButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.durationLabel withOffset:0];
    [self.actionButton autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:0];
}

- (void) setupDurationLabel {
    self.durationLabel = [[UILabel alloc] init];
    self.durationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.durationLabel.textColor = [self lightLabelColor];
    self.durationLabel.font = [self lightLabelFont];

    [self.contentView addSubview:self.durationLabel];
    
    [self.durationLabel autoSetDimension:ALDimensionHeight toSize:kKFStreamTableViewCellLabelHeight];
    [self.durationLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thumbnailImageView withOffset:kKFStreamTableViewCellPadding];
    [self.durationLabel autoPinEdgeToSuperviewEdge:ALEdgeRight withInset:kKFStreamTableViewCellPadding];
}

- (void) actionButtonPressed:(id)sender {
    if (self.actionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.actionBlock();
        });
    }
}

- (void) setupLocationLabel {
    self.locationLabel = [[UILabel alloc] init];
    self.locationLabel.textColor = [self lightLabelColor];
    self.locationLabel.font = [self lightLabelFont];
    self.locationLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.locationLabel];
    
    [self.durationLabel autoSetDimension:ALDimensionHeight toSize:kKFStreamTableViewCellLabelHeight];
    [self.locationLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.dateLabel withOffset:kKFStreamTableViewCellPadding];
    [self.locationLabel autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:kKFStreamTableViewCellPadding];
}

- (UIColor*) lightLabelColor {
    return [UIColor colorWithHue:0 saturation:0 brightness:0.6 alpha:1.0];
}

- (UIFont*) lightLabelFont {
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f];
}

- (void) setupThumbnailView {
    self.thumbnailImageView = [[UIImageView alloc] init];
    self.thumbnailImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.thumbnailImageView];
    [self.thumbnailImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(kKFStreamTableViewCellPadding, kKFStreamTableViewCellPadding, kKFStreamTableViewCellPadding, kKFStreamTableViewCellPadding) excludingEdge:ALEdgeBottom];
    [self.thumbnailImageView autoSetDimension:ALDimensionHeight toSize:180];
}

- (void) setStream:(KFStream *)stream {
    self.dateLabel.text = [[KFDateUtils localizedDateFormatter] stringFromDate:stream.startDate];
    self.locationLabel.text = stream.city;
    self.durationLabel.text = [KFDateUtils timeIntervalStringFromDate:stream.startDate toDate:stream.finishDate];
    __weak KFStreamTableViewCell *weakSelf = self;

    [self.loadingIndicatorView startAnimating];
    self.thumbnailImageView.alpha = 0.0f;
    self.loadingIndicatorView.alpha = 1.0f;
    
    if (stream.isLive) {
        self.liveBannerView.alpha = 1.0f;
    } else {
        self.liveBannerView.alpha = 0.0f;
    }

    [self.thumbnailImageView setImageWithURL:stream.thumbnailURL completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
        weakSelf.thumbnailImageView.image = image;
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.thumbnailImageView.alpha = 1.0f;
            weakSelf.loadingIndicatorView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            [weakSelf.loadingIndicatorView stopAnimating];
        }];
    }];
}

- (void) prepareForReuse {
    [super prepareForReuse];
    [self.thumbnailImageView cancelCurrentImageLoad];
    self.thumbnailImageView.image = nil;
    self.actionBlock = nil;
}

+ (NSString*) cellIdentifier {
    return KFStreamTableViewCellIdentifier;
}

+ (CGFloat) defaultHeight {
    return 240.;
}

@end
