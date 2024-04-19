//
//  ViewStrategyCustomControls.m
//  ViewStrategy
//
//  Copyright © 2024 Brightcove, Inc. All rights reserved.
//

#import "ViewStrategyCustomControls.h"


@interface ViewStrategyCustomControls()

@property (nonatomic, weak) id<BCOVPlaybackController> playbackController;
@property (nonatomic, weak) AVPlayer *player;

@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *durationTimeLabel;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIImage *playImage;
@property (nonatomic, strong) UIImage *pauseImage;
@property (nonatomic, strong) UIButton *playPauseButton;

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
    NSLog(@"Do not call -[%@ initWithCoder:] directly, instead use -[%@ initWithPlaybackController:]",
          self.class, self.class);
    [self doesNotRecognizeSelector:_cmd];

    return nil;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    NSLog(@"Do not call -[%@ initWithFrame:] directly, instead use -[%@ initWithPlaybackController:]",
          self.class, self.class);
    [self doesNotRecognizeSelector:_cmd];

    return nil;
}

- (instancetype)initWithPlaybackController:(id<BCOVPlaybackController>)playbackController
{
    if (self = [super initWithFrame:CGRectZero])
    {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        self.playbackController = playbackController;

        self.currentTimeLabel = ({
            UILabel *currentTimeLabel = [UILabel new];
            currentTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
            currentTimeLabel.text = @"00:00";
            currentTimeLabel.textColor = UIColor.whiteColor;
            currentTimeLabel.font = [UIFont systemFontOfSize:20];
            currentTimeLabel;
        });
        [self addSubview:self.currentTimeLabel];

        self.durationTimeLabel = ({
            UILabel *durationTimeLabel = [UILabel new];
            durationTimeLabel.translatesAutoresizingMaskIntoConstraints = NO;
            durationTimeLabel.text = @"00:00";
            durationTimeLabel.textColor = UIColor.whiteColor;
            durationTimeLabel.font = [UIFont systemFontOfSize:20];
            durationTimeLabel;
        });
        [self addSubview:self.durationTimeLabel];

        self.progressView = ({
            UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
            progressView.translatesAutoresizingMaskIntoConstraints = NO;
            progressView.frame = CGRectMake(0, self.bounds.size.height,
                                            self.bounds.size.width, self.bounds.size.height);
            progressView.progress = 0.0f;
            progressView.backgroundColor = UIColor.whiteColor;
            progressView;
        });
        [self addSubview:self.progressView];

        self.playImage = [UIImage imageNamed:@"play.fill"];

        self.pauseImage = [UIImage imageNamed:@"pause.fill"];

        self.playPauseButton = ({
            UIButton *playPauseButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
            playPauseButton.translatesAutoresizingMaskIntoConstraints = NO;
            playPauseButton.tintColor = UIColor.whiteColor;
            [playPauseButton setImage:self.playImage
                             forState:UIControlStateNormal];
            [playPauseButton addTarget:self
                                action:@selector(playPauseButtonPressed)
                      forControlEvents:UIControlEventTouchUpInside];
            playPauseButton;
        });
        [self addSubview:self.playPauseButton];

        [self setupConstraints];
    }

    return self;
}

- (void)setupConstraints
{
    NSLayoutFormatOptions option = NSLayoutFormatDirectionLeadingToTrailing;
    NSDictionary *views = @{ @"superview": self,
                             @"currentTimeLabel": self.currentTimeLabel,
                             @"durationTimeLabel": self.durationTimeLabel,
                             @"progressView": self.progressView,
                             @"playPauseButton": self.playPauseButton };

    NSArray *hcCurrentTimeLabel = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-20-[currentTimeLabel(>=30,<=100)]"
                                                                          options:option
                                                                          metrics:nil
                                                                            views:views];
    [NSLayoutConstraint activateConstraints:hcCurrentTimeLabel];

    NSArray *vcCurrentTimeLabel = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[currentTimeLabel(50)]-10-|"
                                                                          options:option
                                                                          metrics:nil
                                                                            views:views];
    [NSLayoutConstraint activateConstraints:vcCurrentTimeLabel];

    NSArray *hcDurationTimeLabel = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[durationTimeLabel(>=30,<=100)]-20-|"
                                                                           options:option
                                                                           metrics:nil
                                                                             views:views];
    [NSLayoutConstraint activateConstraints:hcDurationTimeLabel];

    NSArray *vcDurationTimeLabel = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[durationTimeLabel(50)]-10-|"
                                                                           options:option
                                                                           metrics:nil
                                                                             views:views];
    [NSLayoutConstraint activateConstraints:vcDurationTimeLabel];

    NSArray *hcPlayPauseButton = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[playPauseButton]"
                                                                         options:NSLayoutFormatAlignAllCenterX
                                                                         metrics:nil
                                                                           views:views];
    [NSLayoutConstraint activateConstraints:hcPlayPauseButton];

    NSArray *vcPlayPauseButton = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[playPauseButton(50)]-10-|"
                                                                         options:option
                                                                         metrics:nil
                                                                           views:views];
    [NSLayoutConstraint activateConstraints:vcPlayPauseButton];

    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[progressView]|"
                                                                             options:option
                                                                             metrics:nil
                                                                               views:views];
    [NSLayoutConstraint activateConstraints:horizontalConstraints];

    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[progressView(5)]|"
                                                                           options:option
                                                                           metrics:nil
                                                                             views:views];
    [NSLayoutConstraint activateConstraints:verticalConstraints];
}

- (void)playPauseButtonPressed
{
    if (self.player.timeControlStatus == AVPlayerTimeControlStatusPlaying)
    {
        [self.playPauseButton setImage:self.playImage
                              forState:UIControlStateNormal];
        [self.playbackController pause];
    }
    else
    {
        [self.playPauseButton setImage:self.pauseImage
                              forState:UIControlStateNormal];
        [self.playbackController play];
    }
}

+ (NSString *)timeFormatter:(NSTimeInterval)seconds
{
    NSDateComponentsFormatter *dcFormatter = [NSDateComponentsFormatter new];
    dcFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    dcFormatter.allowedUnits = (seconds < 3600 ?
                                NSCalendarUnitMinute | NSCalendarUnitSecond :
                                NSCalendarUnitHour |  NSCalendarUnitMinute | NSCalendarUnitSecond);
    NSString *formatted = [dcFormatter stringFromTimeInterval:seconds];
    return formatted;
}


#pragma mark - BCOVPlaybackSessionConsumer

- (void)didAdvanceToPlaybackSession:(id<BCOVPlaybackSession>)session
{
    self.player = session.player;

    if (self.playbackController.isAutoPlay)
    {
        [self.playPauseButton setImage:self.pauseImage
                              forState:UIControlStateNormal];
    }
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session
          didProgressTo:(NSTimeInterval)progress
{
    if (CMTIME_IS_VALID(session.player.currentItem.duration) &&
        progress > 0)
    {
        self.progressView.progress = progress / CMTimeGetSeconds(session.player.currentItem.duration);
        self.currentTimeLabel.text = [ViewStrategyCustomControls timeFormatter:progress];
    }
}

- (void)playbackSession:(id<BCOVPlaybackSession>)session
      didChangeDuration:(NSTimeInterval)duration
{
    self.durationTimeLabel.text = [ViewStrategyCustomControls timeFormatter:duration];
}

@end
