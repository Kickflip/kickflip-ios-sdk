//
//  KFStreamTableViewCell.m
//  Pods
//
//  Created by Christopher Ballinger on 4/4/14.
//
//

#import "KFStreamTableViewCell.h"
#import "UIImageView+AFNetworking.h"
#import "KFStream.h"
#import "UIView+AutoLayout.h"

static NSString * const KFStreamTableViewCellIdentifier = @"KFStreamTableViewCellIdentifier";

@implementation KFStreamTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupDateLabel];
        [self setupLocationLabel];
        [self setupThumbnailView];
        [self setupDurationLabel];
    }
    return self;
}
                          
- (void) setupDateLabel {
    self.dateLabel = [[UILabel alloc] init];
    [self.contentView addSubview:self.dateLabel];
}

- (void) setupDurationLabel {
    self.durationLabel = [[UILabel alloc] init];
    [self.contentView addSubview:self.durationLabel];
}

- (void) setupLocationLabel {
    self.locationLabel = [[UILabel alloc] init];
    [self.contentView addSubview:self.locationLabel];
}

- (void) setupThumbnailView {
    self.thumbnailImageView = [[UIImageView alloc] init];
    self.thumbnailImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentView addSubview:self.thumbnailImageView];
    NSArray *constraints = [self.thumbnailImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(5, 5, 5, 5) excludingEdge:ALEdgeBottom];
    [self.contentView addConstraints:constraints];
    NSLayoutConstraint *constraint = [self.thumbnailImageView autoSetDimension:ALDimensionHeight toSize:180];
    [self.contentView addConstraint:constraint];
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setStream:(KFStream *)stream {
    self.dateLabel.text = @"4/19/1900 4:19pm";
    self.locationLabel.text = @"Berkeley, CA";
    self.durationLabel.text = @"4m 19s";
    [self.thumbnailImageView setImageWithURL:stream.thumbnailURL];
}

- (void) prepareForReuse {
    [super prepareForReuse];
    self.thumbnailImageView.image = nil;
}

+ (NSString*) cellIdentifier {
    return KFStreamTableViewCellIdentifier;
}

@end
