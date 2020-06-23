//
//  ViewStrategyCustomControls.m
//  ViewStrategy
//
//  Created by Carlos Ceja.
//  Copyright © 2020 Brightcove. All rights reserved.
//

#import "ViewStrategyCustomControls.h"


@interface ViewStrategyCustomControls()

@property (nonatomic, weak) id<BCOVPlaybackController> playbackController;

@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *durationTimeLabel;

@property (nonatomic, strong) UIImageView *playImageView;
@property (nonatomic, strong) UIImageView *pauseImageView;

@property (nonatomic, strong) UIButton *playPauseButton;

@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, assign) BOOL isPlaying;

@end


@implementation ViewStrategyCustomControls

- (instancetype)init
{
    NSLog(@"Do not call -[%@ init] directly, instead use -[%@ initWithPlaybackController:]", self.class, self.class);
    [self doesNotRecognizeSelector:_cmd];

    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    NSLog(@"Do not call -[%@ initWithCoder:] directly, instead use -[%@ initWithPlaybackController:]", self.class, self.class);
    [self doesNotRecognizeSelector:_cmd];

    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSLog(@"Do not call -[%@ initWithFrame:] directly, instead use -[%@ initWithPlaybackController:]", self.class, self.class);
    [self doesNotRecognizeSelector:_cmd];

    return nil;
}

- (instancetype)initWithPlaybackController:(id<BCOVPlaybackController>)playbackController
{
    if (self = [super initWithFrame:CGRectZero])
    {
        _playbackController = playbackController;
        
        [self setup];
        
        [self setupConstraints];
    }
    
    return self;
}

- (void)setup
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    {
        self.currentTimeLabel = [[UILabel alloc] init];
        self.currentTimeLabel.text = @"00:00";
        self.currentTimeLabel.textColor = UIColor.whiteColor;
    }
    
    {
        self.durationTimeLabel = [[UILabel alloc] init];
        self.durationTimeLabel.text = @"00:00";
        self.durationTimeLabel.textColor = UIColor.whiteColor;
    }
    
    {
        self.progressView = [[UIProgressView alloc] init];
        self.progressView.progress = 0.0f;
        self.progressView.backgroundColor = UIColor.whiteColor;
    }
    
    {
        UIImage *originalImage = [UIImage imageNamed:@"PlayButton"];
        UIImage *tintedImage = [originalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        self.playImageView = [[UIImageView alloc] initWithImage:tintedImage];
        self.playImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.playImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.playImageView.tintColor = UIColor.whiteColor;
        self.playImageView.userInteractionEnabled = NO;
        self.playImageView.frame = CGRectMake(0.0f, 0.0f, 30.0f, 30.0f);
        self.playImageView.bounds = CGRectInset(CGRectMake(0.0f, 0.0f, 30.0f, 30.0f), 7.0f, 7.0f);
    }
    
    {
        UIImage *originalImage = [UIImage imageNamed:@"PauseButton"];
        UIImage *tintedImage = [originalImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        
        self.pauseImageView = [[UIImageView alloc] initWithImage:tintedImage];
        self.pauseImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.pauseImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.pauseImageView.tintColor = UIColor.whiteColor;
        self.pauseImageView.userInteractionEnabled = NO;
        self.pauseImageView.frame = CGRectMake(0.0f, 0.0f, 30.0f, 30.0f);
        self.pauseImageView.bounds = CGRectInset(CGRectMake(0.0f, 0.0f, 30.0f, 30.0f), 7.0f, 7.0f);
    }
    
    {
        self.playPauseButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 30.0f, 30.0f)];
        [self.playPauseButton addTarget:self action:@selector(handlePlayPauseButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.playPauseButton addSubview:self.playImageView];
        [self.playPauseButton addSubview:self.pauseImageView];
    }
    
    self.isPlaying = self.playbackController.isAutoPlay;
}

- (void)setupConstraints
{
    {
        UIView *currentTimeLabel = self.currentTimeLabel;
        currentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:currentTimeLabel];
        
        UIView *durationTimeLabel = self.durationTimeLabel;
        durationTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:durationTimeLabel];
        
        UIView *playPauseButton = self.playPauseButton;
        playPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:playPauseButton];
        
        NSLayoutFormatOptions option = NSLayoutFormatDirectionLeadingToTrailing;
        NSDictionary *views = NSDictionaryOfVariableBindings(currentTimeLabel, durationTimeLabel, playPauseButton);
        
        NSArray *hcCurrentTimeLabel = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[currentTimeLabel(>=30,<=50)]" options:option metrics:nil views:views];
    
        NSArray *vcCurrentTimeLabel = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[currentTimeLabel(30)]-10-|" options:option metrics:nil views:views];
        
        NSArray *hcDurationTimeLabel = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[durationTimeLabel(>=30,<=50)]-20-|" options:option metrics:nil views:views];
        
        NSArray *vcDurationTimeLabel = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[durationTimeLabel(30)]-10-|" options:option metrics:nil views:views];
        
        NSArray *hcPlayPauseButton = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[playPauseButton]" options:NSLayoutFormatAlignAllCenterX metrics:nil views:@{ @"superview": self, @"playPauseButton": playPauseButton }];
        
        NSArray *vcPlayPauseButton = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[playPauseButton(30)]-10-|" options:option metrics:nil views:views];

        [self addConstraints:hcCurrentTimeLabel];
        [self addConstraints:vcCurrentTimeLabel];
        [self addConstraints:hcDurationTimeLabel];
        [self addConstraints:vcDurationTimeLabel];
        [self addConstraints:hcPlayPauseButton];
        [self addConstraints:vcPlayPauseButton];
    }

    {
        UIView *view = self.progressView;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:view];
        
        NSLayoutFormatOptions option = NSLayoutFormatDirectionLeadingToTrailing;
        NSDictionary *views = NSDictionaryOfVariableBindings(view);
        
        NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|" options:option metrics:nil views:views];
        
        NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[view(5)]|" options:option metrics:nil views:views];
        
        [self addConstraints:horizontalConstraints];
        [self addConstraints:verticalConstraints];
    }
}

- (void)handlePlayPauseButtonPressed:(id)sender
{
    self.isPlaying = !self.isPlaying;
    
    if (self.isPlaying)
    {
        self.playPauseButton.subviews[0].hidden = YES;
        self.playPauseButton.subviews[1].hidden = NO;
        [self.playbackController play];
    }
    else
    {
        self.playPauseButton.subviews[0].hidden = NO;
        self.playPauseButton.subviews[1].hidden = YES;
        [self.playbackController pause];
        
    }
}

#pragma mark BCOVPlaybackSessionConsumer

- (void)didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    if (self.isPlaying)
    {
        self.playPauseButton.subviews[0].hidden = YES;
    }
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session didProgressTo:(NSTimeInterval)progress
{
    NSTimeInterval duration = CMTimeGetSeconds(session.player.currentItem.duration);
    float percent = progress / duration;
    
    self.progressView.progress = !isnan(percent) ? percent : 0.0f;
    
    if (progress > 0)
    self.currentTimeLabel.text = [ViewStrategyCustomControls timeFormatter:progress];
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session didChangeDuration:(NSTimeInterval)duration
{
    self.durationTimeLabel.text = [ViewStrategyCustomControls timeFormatter:duration];
}


#pragma mark Class functions

+ (NSString *)timeFormatter:(NSTimeInterval)seconds
{
    NSDateComponentsFormatter *dcFormatter = [[NSDateComponentsFormatter alloc] init];
    dcFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    dcFormatter.allowedUnits = NSCalendarUnitMinute | NSCalendarUnitSecond;
    NSString *formatted = [dcFormatter stringFromTimeInterval:seconds];
    return formatted;
}

@end
