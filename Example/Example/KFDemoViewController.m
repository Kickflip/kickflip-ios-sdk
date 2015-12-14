//
//  KFDemoViewController.m
//  Kickflip
//
//  Created by Christopher Ballinger on 1/28/14.
//  Copyright (c) 2014 Kickflip. All rights reserved.
//

#import "KFDemoViewController.h"
#import "Kickflip.h"
#import "KFAPIClient.h"
#import "KFLog.h"
#import "KFUser.h"
#import "YapDatabase.h"
#import "YapDatabaseView.h"
#import "PureLayout.h"
#import "KFDateUtils.h"
#import "KFStreamTableViewCell.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIActionSheet+Blocks.h"
#import "VTAcknowledgementsViewController.h"
#import "KFOnboardingViewController.h"
#import "KFConstants.h"

static NSString * const kKFStreamView = @"kKFStreamView";
static NSString * const kKFStreamsGroup = @"kKFStreamsGroup";
static NSString * const kKFStreamsCollection = @"kKFStreamsCollection";

@interface KFDemoViewController ()
@property (nonatomic, strong, readwrite) UIButton *broadcastButton;
@property (nonatomic, strong) YapDatabase *database;
@property (nonatomic, strong) YapDatabaseConnection *uiConnection;
@property (nonatomic, strong) YapDatabaseConnection *bgConnection;
@property (nonatomic, strong) YapDatabaseViewMappings *mappings;
@property (nonatomic) NSUInteger currentPage;
@end

@implementation KFDemoViewController

- (void) dealloc {
    self.pullToRefreshView = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) broadcastButtonPressed:(id)sender {
    [Kickflip presentBroadcasterFromViewController:self ready:^(KFStream *stream) {
        if (stream.streamURL) {
            DDLogInfo(@"Stream is ready at URL: %@", stream.streamURL);
        }
    } completion:^(BOOL success, NSError* error){
        if (!success) {
            DDLogError(@"Error setting up stream: %@", error);
        } else {
            DDLogInfo(@"Done broadcasting");
        }
    }];
}

- (NSString *) applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (void) setupDatabase {
    NSString *docs = [self applicationDocumentsDirectory];
    NSString *dbPath = [docs stringByAppendingPathComponent:@"kickflip.sqlite"];
    self.database = [[YapDatabase alloc] initWithPath:dbPath];
    self.uiConnection = [self.database newConnection];
    self.bgConnection = [self.database newConnection];
    [self setupDatabaseView];
}

- (void) setupDatabaseView {
    YapDatabaseViewSorting *sorting = [YapDatabaseViewSorting withObjectBlock:^NSComparisonResult(NSString *group, NSString *collection1, NSString *key1, id object1, NSString *collection2, NSString *key2, id object2) {
        if ([group isEqualToString:kKFStreamsGroup]) {
            KFStream *stream1 = object1;
            KFStream *stream2 = object2;
            return [stream2.startDate compare:stream1.startDate];
        }
        return NSOrderedSame;
    }];
    YapDatabaseViewGrouping *grouping = [YapDatabaseViewGrouping withObjectBlock:^NSString *(NSString *collection, NSString *key, id object) {
        if ([object isKindOfClass:[KFStream class]]) {
            KFStream *stream = object;
            // Hide streams without thumbnails for now
            if (!stream.thumbnailURL) {
                return nil;
            }
            return kKFStreamsGroup;
        }
        return nil; // exclude from view
    }];
    
    YapDatabaseView *databaseView = [[YapDatabaseView alloc] initWithGrouping:grouping sorting:sorting];
    
    [self.database registerExtension:databaseView withName:kKFStreamView];
}


- (void) setupNavigationBarAppearance {
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    NSDictionary *attributes = @{NSForegroundColorAttributeName : [UIColor whiteColor],
                                            NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0]};
    [self.navigationController.navigationBar setTitleTextAttributes:attributes];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:71/255.0f green:164/255.0f blue:71/255.0f alpha:1.0f];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void) setupTableView {
    self.streamsTableView = [[UITableView alloc] init];
    self.streamsTableView.dataSource = self;
    self.streamsTableView.delegate = self;
    [self.streamsTableView registerClass:[KFStreamTableViewCell class] forCellReuseIdentifier:[KFStreamTableViewCell cellIdentifier]];
    [self.view addSubview:self.streamsTableView];
    self.streamsTableView.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *constraint = [self.streamsTableView autoPinToTopLayoutGuideOfViewController:self withInset:0.0f];
    [self.view addConstraint:constraint];
    NSArray *constraints = [self.streamsTableView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeTop];
    [self.view addConstraints:constraints];
}

- (void) infoButtonPressed:(id)sender {
    VTAcknowledgementsViewController *viewController = [VTAcknowledgementsViewController acknowledgementsViewController];
    viewController.headerText = NSLocalizedString(@"Kickflip ❤ Open Source", nil); // optional
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void) apiExample {
    [[KFAPIClient sharedClient] requestNewActiveUserWithUsername:@"bob" password:@"secret password" email:@"bob@example.com" displayName:@"Bob Jones" extraInfo:@{@"otherInfo": @"Any other key/values you would want"} callbackBlock:^(KFUser *activeUser, NSError *error) {
        if (activeUser) {
            NSLog(@"great, you've got a new user!");
        }
    }];
    [[KFAPIClient sharedClient] updateMetadataForActiveUserWithNewPassword:nil email:@"test@example.com" displayName:@"Bob Jones II" extraInfo:@{@"otherInfo": @"Any other key/values you would want"}  callbackBlock:^(KFUser *updatedUser, NSError *error) {
        if (updatedUser) {
            NSLog(@"great, you've got updated a user!");
        }
    }];
    
    [[KFAPIClient sharedClient] requestUserInfoForUsername:@"existing-username" callbackBlock:^(KFUser *existingUser, NSError *error) {
        if (existingUser) {
            NSLog(@"you got info for an existing user!");
        }
    }];
    
    [[KFAPIClient sharedClient] loginExistingUserWithUsername:@"existing-username" password:@"password" callbackBlock:^(KFUser *existingUser, NSError *error) {
        if (existingUser) {
            NSLog(@"successfully logged in existing user");
        }
    }];
    
    [[KFAPIClient sharedClient] startNewStream:^(KFStream *newStream, NSError *error) {
        if (newStream) {
            NSLog(@"it's a new stream ready for public broadcast!");
        }
    }];
    
    KFStream *stream = nil;
    
    [[KFAPIClient sharedClient] stopStream:stream callbackBlock:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"Stream stopped");
        }
    }];
    
    [[KFAPIClient sharedClient] updateMetadataForStream:stream callbackBlock:^(KFStream *updatedStream, NSError *error) {
        if (updatedStream) {
            NSLog(@"stream updated!");
        }
    }];
    
    [[KFAPIClient sharedClient] requestStreamsByKeyword:@"skateboard" pageNumber:1 itemsPerPage:10 callbackBlock:^(NSArray *streams, KFPaginationInfo *paginationInfo, NSError *error) {
        NSLog(@"found %d streams", (int)streams.count);
    }];
    
    CLLocation *currentLocation = nil;
    [[KFAPIClient sharedClient] requestStreamsForLocation:currentLocation radius:100 pageNumber:1 itemsPerPage:25 callbackBlock:^(NSArray *streams, KFPaginationInfo *paginationInfo, NSError *error) {
        NSLog(@"found %d streams near %@", (int)streams.count, currentLocation);
    }];
    
    [[KFAPIClient sharedClient] requestStreamsForUsername:@"kickflip-user" pageNumber:1 itemsPerPage:25 callbackBlock:^(NSArray *streams, KFPaginationInfo *paginationInfo, NSError *error) {
        NSLog(@"found %d public streams for user", (int)streams.count);
    }];
}

- (void) setupPullToRefresh {
    self.pullToRefreshView = [[SSPullToRefreshView alloc] initWithScrollView:self.streamsTableView delegate:self];
    self.pullToRefreshView.contentView = [[SSPullToRefreshSimpleContentView alloc] initWithFrame:CGRectZero];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupDatabase];

    [self setupNavigationBarAppearance];

    self.title = @"Kickflip";
    
    UIBarButtonItem *broadcastBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"KFVideoCameraIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(broadcastButtonPressed:)];
    self.navigationItem.rightBarButtonItem = broadcastBarButton;
    
    UIBarButtonItem *infoBarButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"KFInfoIcon"] style:UIBarButtonItemStylePlain target:self action:@selector(infoButtonPressed:)];
    self.navigationItem.leftBarButtonItem = infoBarButton;
    
    /*
    UIImageView *logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"KFLogoTransparent"]];
    logoImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.navigationItem.titleView = logoImageView;
    */
    [self setupViewMappings];
    
    [self setupTableView];
    [self setupPullToRefresh];
}

- (void) setupViewMappings {
    [self.uiConnection beginLongLivedReadTransaction];

    NSArray *groups = @[ kKFStreamsGroup ];
    self.mappings = [[YapDatabaseViewMappings alloc] initWithGroups:groups view:kKFStreamView];
    
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        // One-time initialization
        [self.mappings updateWithTransaction:transaction];
    }];
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(yapDatabaseModified:)
                                                 name:YapDatabaseModifiedNotification
                                               object:self.database];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self refreshStreams];
    
    BOOL hasCompletedOnboarding = [[[NSUserDefaults standardUserDefaults] objectForKey:KFHasCompletedOnboardingKey] boolValue];
    
    if (!hasCompletedOnboarding) {
        KFOnboardingViewController *onboardingViewController = [[KFOnboardingViewController alloc] initWithNibName:NSStringFromClass([KFOnboardingViewController class]) bundle:nil];
        onboardingViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self presentViewController:onboardingViewController animated:NO completion:nil];
    }
}

- (void) refreshStreams {
    [self.pullToRefreshView startLoading];
    self.currentPage = 1;
    [[KFAPIClient sharedClient] requestAllStreamsWithPageNumber:self.currentPage itemsPerPage:10 callbackBlock:^(NSArray *streams, KFPaginationInfo *paginationInfo, NSError *error) {
        if (error) {
            DDLogError(@"Error fetching all streams: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.pullToRefreshView finishLoading];
            });
            return;
        }
        [self.bgConnection asyncReadWriteWithBlock:^(YapDatabaseReadWriteTransaction *transaction) {
            for (KFStream *stream in streams) {
                KFStream *newStream = [[transaction objectForKey:stream.streamID inCollection:kKFStreamsCollection] copy];
                if (!newStream) {
                    newStream = stream;
                } else {
                    [newStream mergeValuesForKeysFromModel:stream];
                }
                [transaction setObject:newStream forKey:stream.streamID inCollection:kKFStreamsCollection];
            }
        } completionQueue:dispatch_get_main_queue()
          completionBlock:^{
            [self.pullToRefreshView finishLoading];
        }];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)sender
{
    return [self.mappings numberOfSections];
}

- (NSInteger)tableView:(UITableView *)sender numberOfRowsInSection:(NSInteger)section
{
    return [self.mappings numberOfItemsInSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [KFStreamTableViewCell defaultHeight];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [KFStreamTableViewCell defaultHeight];
}

- (UITableViewCell *)tableView:(UITableView *)sender cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    __block KFStream *stream = nil;
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        stream = [[transaction extension:kKFStreamView] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    
    KFStreamTableViewCell *cell = [sender dequeueReusableCellWithIdentifier:[KFStreamTableViewCell cellIdentifier]];
    [cell setStream:stream];
    [cell setActionBlock:^{
        KFUser *activeUser = [KFUser activeUser];
        
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:stream];
        NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding];
        DDLogInfo(@"stream json: %@", jsonString);
        
        RIButtonItem *cancelItem = [RIButtonItem itemWithLabel:@"Cancel"];
        RIButtonItem *shareItem = [RIButtonItem itemWithLabel:@"Share" action:^{
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[stream.kickflipURL] applicationActivities:nil];
            UIActivityViewControllerCompletionHandler completionHandler = ^(NSString *activityType, BOOL completed) {
            };
            activityViewController.completionHandler = completionHandler;
            [self presentViewController:activityViewController animated:YES completion:nil];
        }];
        RIButtonItem *otherItem = nil;
        RIButtonItem *flagItem = [RIButtonItem itemWithLabel:@"Flag" action:^{
            NSLog(@"Flag it");
        }];
        RIButtonItem *deleteItem = [RIButtonItem itemWithLabel:@"Delete" action:^{
            NSLog(@"Delete it");
        }];
        if ([stream.username isEqualToString:[activeUser username]]) {
            otherItem = deleteItem;
        } else {
            otherItem = flagItem;
        }
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil cancelButtonItem:cancelItem destructiveButtonItem:otherItem otherButtonItems:shareItem, nil];
        [actionSheet showInView:self.view];
    }];
    return cell;
}

- (void)yapDatabaseModified:(NSNotification *)notification
{
    // Jump to the most recent commit.
    // End & Re-Begin the long-lived transaction atomically.
    // Also grab all the notifications for all the commits that I jump.
    // If the UI is a bit backed up, I may jump multiple commits.
    
    NSArray *notifications = [self.uiConnection beginLongLivedReadTransaction];
    
    // Process the notification(s),
    // and get the change-set(s) as applies to my view and mappings configuration.
    
    NSArray *sectionChanges = nil;
    NSArray *rowChanges = nil;
    
    [[self.uiConnection ext:kKFStreamView] getSectionChanges:&sectionChanges
                                                  rowChanges:&rowChanges
                                            forNotifications:notifications
                                                withMappings:self.mappings];
    
    // No need to update mappings.
    // The above method did it automatically.
    
    if ([sectionChanges count] == 0 & [rowChanges count] == 0)
    {
        // Nothing has changed that affects our tableView
        return;
    }
    
    // Familiar with NSFetchedResultsController?
    // Then this should look pretty familiar
    
    [self.streamsTableView beginUpdates];
    
    for (YapDatabaseViewSectionChange *sectionChange in sectionChanges)
    {
        switch (sectionChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.streamsTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.streamsTableView insertSections:[NSIndexSet indexSetWithIndex:sectionChange.index]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            default:
                break;
        }
    }
    
    for (YapDatabaseViewRowChange *rowChange in rowChanges)
    {
        switch (rowChange.type)
        {
            case YapDatabaseViewChangeDelete :
            {
                [self.streamsTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeInsert :
            {
                [self.streamsTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeMove :
            {
                [self.streamsTableView deleteRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.streamsTableView insertRowsAtIndexPaths:@[ rowChange.newIndexPath ]
                                      withRowAnimation:UITableViewRowAnimationAutomatic];
                break;
            }
            case YapDatabaseViewChangeUpdate :
            {
                [self.streamsTableView reloadRowsAtIndexPaths:@[ rowChange.indexPath ]
                                      withRowAnimation:UITableViewRowAnimationNone];
                break;
            }
        }
    }
    
    [self.streamsTableView endUpdates];
}


- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    __block KFStream *stream = nil;
    [self.uiConnection readWithBlock:^(YapDatabaseReadTransaction *transaction) {
        stream = [[transaction extension:kKFStreamView] objectAtIndexPath:indexPath withMappings:self.mappings];
    }];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    MPMoviePlayerViewController *movieView = [[MPMoviePlayerViewController alloc] initWithContentURL:stream.streamURL];
    [self presentViewController:movieView animated:YES completion:nil];
}

- (void)pullToRefreshViewDidStartLoading:(SSPullToRefreshView *)view {
    [self refreshStreams];
}


@end
