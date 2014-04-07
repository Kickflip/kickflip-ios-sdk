//
//  KFStreamTableViewCell.h
//  Pods
//
//  Created by Christopher Ballinger on 4/4/14.
//
//

#import <UIKit/UIKit.h>
@class KFStream;

typedef void(^KFStreamTableViewCellActionBlock)(void);

@interface KFStreamTableViewCell : UITableViewCell

@property (nonatomic, strong) UIImageView *thumbnailImageView;
@property (nonatomic, strong) UILabel *locationLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UILabel *durationLabel;
@property (nonatomic, strong) UIButton *actionButton;
@property (nonatomic, copy) KFStreamTableViewCellActionBlock actionBlock;

- (void) setStream:(KFStream*)stream;

+ (NSString*) cellIdentifier;
+ (CGFloat) defaultHeight;

@end
