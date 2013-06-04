//
//  SMPViewController.m
//  StreamingMusicPlayer
//
//  Created by Maxim Mikheev on 03.06.13.
//  Copyright (c) 2013 Maxim Mikheev. All rights reserved.
//

#import "SMPViewController.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@interface SMPViewController ()

@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, weak) IBOutlet UIView *volumeControlView;
@property (nonatomic, weak) IBOutlet UILabel *track;
@property (nonatomic, weak) IBOutlet UIButton *playPauseButton;
@property (nonatomic) BOOL isPlayingNow;

@end

@implementation SMPViewController {}

#pragma mark - Audio Playback Prepare Methods

/// Method prepares Audio Session for playback in background
- (void)prepareAudioSession {
    // Set the audio category of this app to playback.
    NSError *setCategoryError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
                                           error:&setCategoryError];
    if (setCategoryError) {
        // Add error handling
    }
    
    // Activate the audio session
    NSError *activationError = nil;
    [[AVAudioSession sharedInstance] setActive:YES error:&activationError];
    if (activationError) {
        // Add error handling
    }
    
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"6.0")) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(playPauseOnInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:nil];
    }
}

/// Method prepares AVPlayer for loading streaming audio
- (void)prepareAudioPlayerWithURL:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    
    self.playerItem = [AVPlayerItem playerItemWithURL:url];
    [self.playerItem addObserver:self
                      forKeyPath:@"timedMetadata"
                         options:NSKeyValueObservingOptionNew
                         context:NULL];
    
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    //self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
}

/// Method prepares Volume control
- (void)prepareVolumeControl {
    self.volumeControlView.backgroundColor = [UIColor clearColor];
    MPVolumeView *myVolumeView = [[MPVolumeView alloc] initWithFrame:self.volumeControlView.bounds];
    [self.volumeControlView addSubview:myVolumeView];
}

#pragma mark - View Lifecycle Methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self prepareAudioSession];
    // Working test url: http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8
    [self prepareAudioPlayerWithURL:@"http://dubweiser.ru:8000/"];
    [self prepareVolumeControl];
    
    self.isPlayingNow = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
    [super viewWillDisappear:animated];
}

#pragma mark - Metadata Methods

/// Method updates music metadata 
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"timedMetadata"]) {
        self.playerItem = object;
        
        for (AVMetadataItem *metadata in self.playerItem.timedMetadata) {
            NSLog(@"TimedMetadata %@", metadata);
            NSLog(@"value = %@", metadata.value);
            self.track.text = (NSString *)metadata.value;
            
            Class playingInfoCenter = NSClassFromString(@"MPNowPlayingInfoCenter");
            
            if (playingInfoCenter) {
                MPNowPlayingInfoCenter *center = [MPNowPlayingInfoCenter defaultCenter];
                NSDictionary *songInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                          (NSString *)metadata.value, MPMediaItemPropertyTitle,
                                          nil];
                center.nowPlayingInfo = songInfo;
            }
        }
    }
}

#pragma mark - Play/Pause Methods

/// Method starts playing streaming music and changes interface accordingly
- (void)playAudio {
    [self.player play];
    self.isPlayingNow = YES;
    [self.playPauseButton setTitle:@"Pause" forState:UIControlStateNormal];
}

/// Method stops playing streaming music and changes interface accordingly
- (void)pauseAudio {
    [self.player pause];
    self.isPlayingNow = NO;
    [self.playPauseButton setTitle:@"Play" forState:UIControlStateNormal];
}

/// Method hangles play/pause toggle
- (void)togglePlayPauseAudio {
    if (self.isPlayingNow) {
        [self pauseAudio];
    } else {
        [self playAudio];
    }
}

/// Method handles Play/Pause button press
- (IBAction)playPauseButtonPressed:(id)sender {
    [self togglePlayPauseAudio];
}

#pragma mark - Remote Control Methods

/// We want to recieve remote control events
- (BOOL)canBecomeFirstResponder {
    return YES;
}

/// Method handles remote control events
- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    // If it is a remote control event handle it correctly
    if (event.type == UIEventTypeRemoteControl) {
        if (event.subtype == UIEventSubtypeRemoteControlPlay) {
            [self playAudio];
        } else if (event.subtype == UIEventSubtypeRemoteControlPause) {
            [self pauseAudio];
        } else if (event.subtype == UIEventSubtypeRemoteControlTogglePlayPause) {
            [self togglePlayPauseAudio];
        }
    }
}

#pragma mark - AVAudioSessionDelegate Methods (prior to iOS 6.x)

/// Method handles interruption's beginning on iOS prior to 6.x
- (void)beginInterruption {
    [self pauseAudio];
}

/// Method handles interruption's end on iOS prior to 6.x
- (void)endInterruption {
    [self playAudio];
}

#pragma mark - Notifications Interruptions Methods (iOS 6.x and higher)

/// Handle interruption on iOS 6.x and higher
- (void)playPauseOnInterruption:(NSNotification *)notification {
    NSInteger interruptionStatus = [[[notification userInfo] objectForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    NSLog(@"status = %d", interruptionStatus);
    
    NSDictionary *info = [notification userInfo];
    NSLog(@"info = %@", info);
    
    if (interruptionStatus == AVAudioSessionInterruptionTypeBegan) {
        [self pauseAudio];
    } else if (interruptionStatus == AVAudioSessionInterruptionTypeEnded) {
        [self playAudio];
    }
}

@end
