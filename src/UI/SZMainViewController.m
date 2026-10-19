#import "SZMainViewController.h"
#import "SZTagButton.h"
#import "SZRadarView.h"
#import "SZAudioRecorder.h"
#import "SZSignatureGenerator.h"
#import "SZShazamClient.h"
#import "SZHistoryStore.h"
#import "SZSettings.h"
#import "SZTheme.h"
#import "SZCommon.h"
#import "SZModern.h"
#import "SZTrackViewController.h"
#import "SZHistoryViewController.h"
#import "SZSettingsViewController.h"
#import <AudioToolbox/AudioToolbox.h>

@interface SZMainViewController () {
    SZRadarView *_radarView;
    SZTagButton *_tagButton;
    UILabel *_statusLabel;
    UILabel *_subStatusLabel;
    UIActivityIndicatorView *_spinner;
    BOOL _isProcessing;
}
@end

@implementation SZMainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = L(@"APP_NAME");
    self.view.backgroundColor = [SZTheme backgroundDark];

    // Left navigation item: My Tags
    UIBarButtonItem *historyItem = [[UIBarButtonItem alloc] initWithTitle:L(@"MY_TAGS")
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(openHistory)];
    self.navigationItem.leftBarButtonItem = historyItem;

    // Right navigation item: Settings
    UIBarButtonItem *settingsItem = [[UIBarButtonItem alloc] initWithTitle:L(@"SETTINGS")
                                                                     style:UIBarButtonItemStyleBordered
                                                                    target:self
                                                                    action:@selector(openSettings)];
    self.navigationItem.rightBarButtonItem = settingsItem;

    // Radar view (concentric sonar waves)
    _radarView = [[SZRadarView alloc] initWithFrame:self.view.bounds];
    _radarView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_radarView];

    // Central Shazam Tag Button
    CGFloat btnSize = SZIsPad() ? 220.0f : 180.0f;
    _tagButton = [[SZTagButton alloc] initWithFrame:CGRectMake(0, 0, btnSize, btnSize)];
    [_tagButton addTarget:self action:@selector(tagButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_tagButton];

    // Main status label ("Touch to Shazam" / "Listening..." / "Tagging...")
    _statusLabel = [[UILabel alloc] init];
    _statusLabel.backgroundColor = [UIColor clearColor];
    _statusLabel.textColor = [SZTheme textPrimary];
    _statusLabel.font = [UIFont boldSystemFontOfSize:SZIsPad() ? 24.0f : 20.0f];
    _statusLabel.textAlignment = NSTextAlignmentCenter;
    _statusLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.75];
    _statusLabel.shadowOffset = CGSizeMake(0, -1);
    _statusLabel.text = L(@"TOUCH_TO_SHAZAM");
    _statusLabel.numberOfLines = 2;
    [self.view addSubview:_statusLabel];

    // Sub-status / helper label
    _subStatusLabel = [[UILabel alloc] init];
    _subStatusLabel.backgroundColor = [UIColor clearColor];
    _subStatusLabel.textColor = [SZTheme textSecondary];
    _subStatusLabel.font = [UIFont systemFontOfSize:SZIsPad() ? 16.0f : 13.0f];
    _subStatusLabel.textAlignment = NSTextAlignmentCenter;
    _subStatusLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    _subStatusLabel.shadowOffset = CGSizeMake(0, -1);
    _subStatusLabel.text = @"";
    [self.view addSubview:_subStatusLabel];

    // Spinner
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _spinner.hidesWhenStopped = YES;
    [self.view addSubview:_spinner];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(historyChanged)
                                                 name:SZHistoryDidChangeNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [SZTheme applyNavigationTheme:self.navigationController.navigationBar];
    [self updateHistoryBadge];

    if ([SZSettings sharedSettings].autoListenOnLaunch && !_isProcessing && ![[SZAudioRecorder sharedRecorder] isRecording]) {
        [self startListening];
    }
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGRect bounds = self.view.bounds;
    UIEdgeInsets insets = SZSafeAreaInsets(self.view);

    CGFloat usableTop = insets.top;
    CGFloat usableHeight = bounds.size.height - usableTop - insets.bottom;

    // Center button at ~44% from usable top
    CGFloat centerY = usableTop + usableHeight * 0.44f;
    CGFloat centerX = CGRectGetMidX(bounds);

    _tagButton.center = CGPointMake(centerX, centerY);
    _radarView.frame = bounds;

    CGFloat btnSize = _tagButton.frame.size.height;
    CGFloat labelWidth = bounds.size.width - 40.0f;

    _statusLabel.frame = CGRectMake((bounds.size.width - labelWidth) * 0.5f,
                                    centerY + btnSize * 0.5f + 32.0f,
                                    labelWidth, 48.0f);

    _subStatusLabel.frame = CGRectMake((bounds.size.width - labelWidth) * 0.5f,
                                       CGRectGetMaxY(_statusLabel.frame) + 6.0f,
                                       labelWidth, 24.0f);

    _spinner.center = CGPointMake(centerX, CGRectGetMaxY(_statusLabel.frame) + 36.0f);
}

- (void)updateHistoryBadge
{
    NSUInteger count = [SZHistoryStore sharedStore].tracks.count;
    if (count > 0) {
        self.navigationItem.leftBarButtonItem.title = [NSString stringWithFormat:@"%@ (%lu)", L(@"MY_TAGS"), (unsigned long)count];
    } else {
        self.navigationItem.leftBarButtonItem.title = L(@"MY_TAGS");
    }
}

- (void)historyChanged
{
    [self updateHistoryBadge];
}

- (void)tagButtonTapped
{
    if (_isProcessing) return;

    if ([[SZAudioRecorder sharedRecorder] isRecording]) {
        // User tapped while listening -> Cancel
        [[SZAudioRecorder sharedRecorder] cancelRecording];
        [self resetUIState];
    } else {
        [self startListening];
    }
}

- (void)startListening
{
    NSTimeInterval duration = [SZSettings sharedSettings].listenDuration;
    _statusLabel.text = L(@"LISTENING");
    _subStatusLabel.text = @"";
    [_tagButton startListeningPulse];
    [_radarView startPulsing];

    __weak typeof(self) weakSelf = self;
    BOOL started = [[SZAudioRecorder sharedRecorder]
        startRecordingWithDuration:duration
        onLevel:^(float level) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                strongSelf->_radarView.audioLevel = level;
            }
        }
        completion:^(NSData *pcmData, NSError *error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (strongSelf) {
                [strongSelf handleAudioCaptureFinished:pcmData error:error];
            }
        }];

    if (!started) {
        [self resetUIState];
        _statusLabel.text = L(@"MIC_PERMISSION_DENIED");
    }
}

- (void)handleAudioCaptureFinished:(NSData *)pcmData error:(NSError *)error
{
    [_radarView stopPulsing];
    [_tagButton stopListeningPulse];

    if (error || !pcmData.length) {
        [self resetUIState];
        _statusLabel.text = error.localizedDescription ?: L(@"NO_MATCH");
        return;
    }

    _isProcessing = YES;
    _statusLabel.text = L(@"TAGGING");
    _subStatusLabel.text = @"";
    [_spinner startAnimating];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSUInteger count = pcmData.length / sizeof(int16_t);
        NSUInteger sampleMs = (NSUInteger)((double)count / 16000.0 * 1000.0);
        NSString *uri = [SZSignatureGenerator signatureURIFromPCMData:pcmData];

        if (!uri.length) {
            SZMain(^{
                [self resetUIState];
                self->_statusLabel.text = L(@"NO_MATCH");
            });
            return;
        }

        SZLog(@"Signature generated successfully (%lu chars). Sending to Shazam...", (unsigned long)uri.length);

        [[SZShazamClient sharedClient]
            recognizeWithSignatureURI:uri
            sampleMs:sampleMs
            completion:^(SZTrack *track, NSError *recogError) {
                [self resetUIState];

                if (recogError) {
                    if (recogError.code == SZErrorNetwork) {
                        // Offline: save signature to history for later tagging
                        SZTrack *offlineTrack = [[SZTrack alloc] init];
                        offlineTrack.pendingSignatureURI = uri;
                        offlineTrack.tagDate = [NSDate date];
                        [[SZHistoryStore sharedStore] addTrack:offlineTrack];
                        self->_statusLabel.text = L(@"OFFLINE_SAVED");
                    } else {
                        self->_statusLabel.text = recogError.localizedDescription ?: L(@"NO_MATCH");
                    }
                    return;
                }

                if (track) {
                    // Success! Vibrate if configured
                    if ([SZSettings sharedSettings].vibrateOnMatch) {
                        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                    }

                    // Save to history
                    [[SZHistoryStore sharedStore] addTrack:track];

                    // Open Track view
                    SZTrackViewController *vc = [[SZTrackViewController alloc] initWithTrack:track];
                    [self.navigationController pushViewController:vc animated:YES];
                } else {
                    self->_statusLabel.text = L(@"NO_MATCH");
                }
            }];
    });
}

- (void)resetUIState
{
    _isProcessing = NO;
    [_spinner stopAnimating];
    [_radarView stopPulsing];
    [_tagButton stopListeningPulse];
    _statusLabel.text = L(@"TOUCH_TO_SHAZAM");
    _subStatusLabel.text = @"";
}

- (void)openHistory
{
    SZHistoryViewController *vc = [[SZHistoryViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [SZTheme applyNavigationTheme:nav.navigationBar];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)openSettings
{
    SZSettingsViewController *vc = [[SZSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
    [SZTheme applyNavigationTheme:nav.navigationBar];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
