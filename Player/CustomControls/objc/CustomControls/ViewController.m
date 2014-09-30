//
//  ViewController.m
//  CustomControls
//
//  Created by Michael Moscardini on 10/30/14.
//  Copyright (c) 2014 Brightcove. All rights reserved.
//

#import "ViewController.h"

#import "ControlsViewController.h"


// ** Customize these values with your own account information **
static NSString * const kViewControllerCatalogToken = @"ZUPNyrUqRdcAtjytsjcJplyUc9ed8b0cD_eWIe36jXqNWKzIcE6i8A..";
static NSString * const kViewControllerPlaylistID = @"3637400917001";


@interface ViewController () <BCOVPlaybackControllerDelegate, ControlsViewControllerFullScreenDelegate>

@property (nonatomic, strong) BCOVCatalogService *catalogService;
@property (nonatomic, strong) id<BCOVPlaybackController> playbackController;
@property (nonatomic, strong) UIView *videoView;
@property (nonatomic, weak) IBOutlet UIView *videoContainer;

@property (nonatomic, strong) ControlsViewController *controlsViewController;
@property (nonatomic, strong) UIViewController *fullscreenViewController;

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
    _videoView = [[UIView alloc] init];
    _fullscreenViewController = [[UIViewController alloc] init];
    _controlsViewController = [[ControlsViewController alloc] init];
    _controlsViewController.delegate = self;

    _playbackController = [[BCOVPlayerSDKManager sharedManager] createPlaybackController];
    _playbackController.delegate = self;
    _playbackController.autoAdvance = YES;
    _playbackController.autoPlay = YES;
    [_playbackController setAllowsExternalPlayback:YES];
    [_playbackController addSessionConsumer:_controlsViewController];

    _catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    self.playbackController.view.frame = self.videoView.bounds;
    self.playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoView addSubview:self.playbackController.view];

    [self addChildViewController:self.controlsViewController];
    self.controlsViewController.view.frame = self.videoView.bounds;
    [self.videoView addSubview:self.controlsViewController.view];
    [self.controlsViewController didMoveToParentViewController:self];

    self.videoView.frame = self.videoContainer.bounds;
    self.videoView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [self.videoContainer addSubview:self.videoView];

    [self requestContentFromCatalog];
}

- (void)handleEnterFullScreenButtonPressed
{
    [self.fullscreenViewController addChildViewController:self.controlsViewController];
    self.videoView.frame = self.fullscreenViewController.view.bounds;
    [self.fullscreenViewController.view addSubview:self.videoView];
    [self.controlsViewController didMoveToParentViewController:self.fullscreenViewController];

    [self presentViewController:self.fullscreenViewController animated:NO completion:nil];
}

- (void)handleExitFullScreenButtonPressed
{
    [self dismissViewControllerAnimated:NO completion:^{

        self.videoView.frame = self.videoContainer.bounds;
        [self addChildViewController:self.controlsViewController];
        [self.videoContainer addSubview:self.videoView];
        [self.controlsViewController didMoveToParentViewController:self];

    }];
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

#pragma mark BCOVPlaybackControllerDelegate

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
