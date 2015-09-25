//
//  BCOVBasicCollectionViewController.m
//  VideoCloudBasicPlayer
//
//  Created by Jon Gherardini on 9/24/15.
//  Copyright (c) 2015 Brightcove. All rights reserved.
//

#import "BCOVBasicCollectionViewController.h"

@interface BCOVBasicCollectionViewController () <BCOVPlaybackControllerDelegate>

@property (nonatomic, strong) BCOVCatalogService *catalogService;
@property (nonatomic, strong) NSArray * playbackControllers; // of type id<BCOVPlaybackController>
@property (nonatomic, strong) NSMutableArray * isPlaybackInitialized; // of type NSNumber as BOOL (use boolValue)
@property (weak, nonatomic) IBOutlet UICollectionView *videoCollectionView;
@property (nonatomic) NSInteger numberOfVideos;
@end

@implementation BCOVBasicCollectionViewController

static NSString * const reuseIdentifier = @"Playback Controller View Cell";
static NSString * const kViewControllerCatalogToken = @"TOKEN_REDACTED";
static NSString * const kViewControllerPlaylistID = @"4504410987001";

#pragma mark Properties

- (NSArray *)isPlaybackInitialized
{
    if (!_isPlaybackInitialized) {
        _isPlaybackInitialized = [[NSMutableArray alloc] initWithCapacity:self.numberOfVideos];
        for (int i = 0; i < self.numberOfVideos; ++i) {
            _isPlaybackInitialized[i] = @(NO);
        }
    }
    return _isPlaybackInitialized;
}

- (NSInteger)numberOfVideos
{
    // For now, this is a pseudo-const property that we hardcode
    // In the future, we may choose to make it be dynamic, such as the number of videos in a playlist
    _numberOfVideos = 6;
    
    return _numberOfVideos;
}

#pragma mark Lifecycle/setup Methods

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
    
    NSMutableArray *playbackControllers = [[NSMutableArray alloc] initWithCapacity:self.numberOfVideos];
    for (int i = 0; i < self.numberOfVideos; ++i) {
        id<BCOVPlaybackController> playbackController = [manager createPlaybackControllerWithViewStrategy:[manager defaultControlsViewStrategy]];
        playbackController.delegate = self;
        playbackController.autoAdvance = YES;
        playbackController.autoPlay = YES;
        [playbackControllers insertObject:playbackController atIndex:i];
    };
    _playbackControllers = [playbackControllers copy]; // explicit get a non-mutable copy
    
    _catalogService = [[BCOVCatalogService alloc] initWithToken:kViewControllerCatalogToken];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
}

#pragma mark Helper methods

- (void)requestContentFromCatalogForPlaybackController:(id<BCOVPlaybackController>)playbackController
{
    [self.catalogService findPlaylistWithPlaylistID:kViewControllerPlaylistID parameters:nil completion:^(BCOVPlaylist *playlist, NSDictionary *jsonResponse, NSError *error) {
        
        if (playlist)
        {
            [playbackController setVideos:playlist.videos];
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

- (void)playbackController:(id<BCOVPlaybackController>)controller playbackSession:(id<BCOVPlaybackSession>)session didReceiveLifecycleEvent:(BCOVPlaybackSessionLifecycleEvent *)lifecycleEvent
{
    NSLog(@"Received lifecycle event of type %@ for controller %lu", lifecycleEvent.eventType, (unsigned long)[self.playbackControllers indexOfObject:controller]);
}

#pragma mark UI Styling

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.numberOfVideos;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    // Configure the cell
    NSInteger videoIndex = indexPath.item;
    id<BCOVPlaybackController> playbackController = self.playbackControllers[videoIndex];
    playbackController.view.frame = cell.bounds;
    playbackController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [cell addSubview:playbackController.view];
    
    if (![self.isPlaybackInitialized[videoIndex] boolValue]) {
        [self requestContentFromCatalogForPlaybackController:playbackController];
        self.isPlaybackInitialized[videoIndex] = @(YES);
    } else {
        [playbackController play];
    }
    
    return cell;
}

#pragma mark <UICollectionViewDelegate>

// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    id<BCOVPlaybackController> playbackController = self.playbackControllers[indexPath.item];
    [playbackController pause];
}

@end
