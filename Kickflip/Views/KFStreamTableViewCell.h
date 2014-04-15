//
//  KFStreamTableViewCell.h
//  Pods
//
//  Created by Christopher Ballinger on 4/4/14.
//
//

#import <UIKit/UIKit.h>
#import "KFLiveBannerView.h"
@class KFStream;

typedef void(^KFStreamTableViewCellActionBlock)(void);

/**
 *  KFStreamTableViewCell is a convenient view for displaying a KFStream in a UITableView
 */
@interface KFStreamTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, copy) KFStreamTableViewCellActionBlock actionBlock;
@property (nonatomic, strong) UIActivityIndicatorView *loadingIndicatorView;
@property (nonatomic, strong) KFLiveBannerView *liveBannerView;

- (void) setStream:(KFStream*)stream;

+ (NSString*) cellIdentifier;
+ (CGFloat) defaultHeight;

@end
