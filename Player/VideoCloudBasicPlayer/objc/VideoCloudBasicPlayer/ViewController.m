//
//  ViewController.m
//  VideoCloudBasicPlayer
//
//  Created by Mike Moscardini on 9/29/14.
//  Copyright (c) 2014 Brightcove. All rights reserved.
//

#import "ViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerCatalogToken = @"ZUPNyrUqRdcAtjytsjcJplyUc9ed8b0cD_eWIe36jXqNWKzIcE6i8A..";
static NSString * const kViewControllerPlaylistID = @"3637400917001";


@interface ViewController () <BCOVPlaybackControllerDelegate, BCOVPUIPlayerViewDelegate>

@property (nonatomic, strong) BCOVCatalogService *catalogService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic) BCOVPUIPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

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

    BCOVPUIBasicControlView *controlsView = [BCOVPUIBasicControlView basicControlViewWithVODLayout];
    BCOVPUIPlayerView *playerView = [[BCOVPUIPlayerView alloc] initWithPlaybackController:self.playbackController options:options controlsView:controlsView ];
    playerView.delegate = self;
    playerView.frame = _videoContainer.bounds;
    playerView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [_videoContainer addSubview:playerView];
    _playerView = playerView;
    _playerView.playbackController = _playbackController;

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

#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

@end

