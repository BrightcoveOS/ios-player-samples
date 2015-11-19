//
//  ViewController.m
//  BasicPlayerUI
//
//  Created by Mike Moscardini on 5/28/15.
//  Copyright (c) 2015 Brightcove. All rights reserved.
//

#import "ViewController.h"

@import BrightcovePlayerSDK;
@import BrightcovePlayerUI;


// ** Customize these values with your own account information **
static NSString * const kViewControllerCatalogToken = @"ZUPNyrUqRdcAtjytsjcJplyUc9ed8b0cD_eWIe36jXqNWKzIcE6i8A..";
static NSString * const kViewControllerPlaylistID = @"3637400917001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, strong) BCOVCatalogService *catalogService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, weak) BCOVPUIPlayerView *playerView;

@end


@implementation ViewController

#pragma mark Setup Methods

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    BCOVPlayerSDKManager *manager = [BCOVPlayerSDKManager sharedManager];

    _playbackController = [manager createPlaybackController];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;

    _catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    BCOVPUIPlayerViewOptions *options = [[BCOVPUIPlayerViewOptions alloc] init];
    options.presentingViewController = self;

    BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:options];
    playerView.delegate = self;
    self.playerView = playerView;

    [self.videoContainer addSubview:self.playerView];
    [ViewController addConstraintsForView:self.playerView];

    [self requestContentFromCatalog];
}

- (void)requestContentFromCatalog
{
    [self.catalogService findPlaylistWithPlaylistID:kViewControllerPlaylistID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {

        if (playlist)
        {
            [self.playbackController setVideos:playlist.videos];
        }
        else
        {
            NSLog(@"ViewController Debug - Error retrieving playlist: `%@`", error);
        }

    }];
}

#pragma mark BCOVPlaybackControllerDelegate Methods

- (void)playbackController:(id<BCOVPlaybackController>)controller didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    NSLog(@"ViewController Debug - Advanced to new session.");
}

- (void)playerView:(BCOVPUIPlayerView *)playerView didTransitionToScreenMode:(BCOVPUIScreenMode)screenMode
{
    NSLog(@"ViewController Debug - Transitioned Screen mode.");
}

#pragma mark UI Styling

+ (void)addConstraintsForView:(UIView *)view
{
    view.translatesAutoresizingMaskIntoConstraints = NO;

    NSLayoutFormatOptions option = NSLayoutFormatDirectionLeadingToTrailing;
    NSDictionary *views = NSDictionaryOfVariableBindings(view);

    NSArray *horizontalConstrains = [NSLayoutConstraint constraintsWithVisualFormat:@"|[view]|" options:option metrics:nil views:views];
    NSArray *verticalConstrains = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|" options:option metrics:nil views:views];

    [view.superview addConstraints:horizontalConstrains];
    [view.superview addConstraints:verticalConstrains];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end
