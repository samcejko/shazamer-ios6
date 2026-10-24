#import "SZTrackViewController.h"
#import "SZLyricsViewController.h"
#import "SZShazamClient.h"
#import "SZHistoryStore.h"
#import "SZUtils.h"
#import "SZTheme.h"
#import "SZCommon.h"
#import "SZModern.h"
#import <QuartzCore/QuartzCore.h>

@interface SZTrackViewController () <UIActionSheetDelegate> {
    UIScrollView *_scrollView;
    UIImageView *_coverImageView;
    UIActivityIndicatorView *_imageSpinner;
    UILabel *_titleLabel;
    UILabel *_artistLabel;
    UILabel *_albumLabel;
    UIButton *_muzikaButton;
    UIButton *_spot6Button;
    UIButton *_tubieButton;
    UIButton *_lyricsButton;
    UIButton *_favoriteButton;
    UIButton *_appleMusicButton;
    UIView *_infoCard;
    UIPopoverController *_activityPopover;
}
@end

@implementation SZTrackViewController

- (instancetype)initWithTrack:(SZTrack *)track
{
    self = [super init];
    if (self) {
        _track = track;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = L(@"DETAILS");
    self.view.backgroundColor = [SZTheme backgroundDark];

    UIBarButtonItem *shareItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(shareTapped)];
    self.navigationItem.rightBarButtonItem = shareItem;

    _scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _scrollView.alwaysBounceVertical = YES;
    [self.view addSubview:_scrollView];

    // Cover art frame with shadow
    _coverImageView = [[UIImageView alloc] init];
    _coverImageView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:1.0];
    _coverImageView.contentMode = UIViewContentModeScaleAspectFill;
    _coverImageView.clipsToBounds = YES;
    _coverImageView.layer.cornerRadius = 8.0;
    _coverImageView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.2].CGColor;
    _coverImageView.layer.borderWidth = 1.0;
    [_scrollView addSubview:_coverImageView];

    _imageSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    _imageSpinner.hidesWhenStopped = YES;
    [_coverImageView addSubview:_imageSpinner];

    // Track Title
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.backgroundColor = [UIColor clearColor];
    _titleLabel.textColor = [SZTheme textPrimary];
    _titleLabel.font = [UIFont boldSystemFontOfSize:SZIsPad() ? 24.0f : 20.0f];
    _titleLabel.textAlignment = UITextAlignmentCenter;
    _titleLabel.numberOfLines = 2;
    _titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.7];
    _titleLabel.shadowOffset = CGSizeMake(0, -1);
    _titleLabel.text = _track.title ?: @"";
    [_scrollView addSubview:_titleLabel];

    // Artist
    _artistLabel = [[UILabel alloc] init];
    _artistLabel.backgroundColor = [UIColor clearColor];
    _artistLabel.textColor = [SZTheme accentCyan];
    _artistLabel.font = [UIFont boldSystemFontOfSize:SZIsPad() ? 18.0f : 16.0f];
    _artistLabel.textAlignment = UITextAlignmentCenter;
    _artistLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    _artistLabel.shadowOffset = CGSizeMake(0, -1);
    _artistLabel.text = _track.artist ?: @"";
    [_scrollView addSubview:_artistLabel];

    // Only show metadata supplied by the recognition service.
    _albumLabel = [[UILabel alloc] init];
    _albumLabel.backgroundColor = [UIColor clearColor];
    _albumLabel.textColor = [SZTheme textSecondary];
    _albumLabel.font = [UIFont systemFontOfSize:SZIsPad() ? 15.0f : 13.0f];
    _albumLabel.textAlignment = UITextAlignmentLeft;
    _albumLabel.numberOfLines = 0;
    _albumLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    _albumLabel.shadowOffset = CGSizeMake(0, -1);
    NSMutableArray *details = [NSMutableArray array];
    NSArray *fields = @[@[L(@"ALBUM"), _track.album ?: @""],
                        @[L(@"RELEASE_DATE"), _track.releaseDate ?: @""],
                        @[L(@"GENRE"), _track.genre ?: @""],
                        @[L(@"LABEL"), _track.label ?: @""],
                        @[@"ISRC", _track.isrc ?: @""]];
    for (NSArray *field in fields) if ([[field objectAtIndex:1] length]) {
        [details addObject:[NSString stringWithFormat:@"%@: %@", [field objectAtIndex:0], [field objectAtIndex:1]]];
    }
    if (_track.duration > 0) {
        NSUInteger seconds = (NSUInteger)_track.duration;
        NSString *duration = seconds >= 3600
            ? [NSString stringWithFormat:@"%lu:%02lu:%02lu", (unsigned long)(seconds / 3600), (unsigned long)((seconds / 60) % 60), (unsigned long)(seconds % 60)]
            : [NSString stringWithFormat:@"%lu:%02lu", (unsigned long)(seconds / 60), (unsigned long)(seconds % 60)];
        [details addObject:[NSString stringWithFormat:@"%@: %@", L(@"TRACK_DURATION"), duration]];
    }
    _albumLabel.text = [details componentsJoinedByString:@"\n"];
    [_scrollView addSubview:_albumLabel];

    _favoriteButton = [self createActionButtonWithTitle:@"" tint:[SZTheme shazamBlue] action:@selector(toggleFavorite)];
    [_scrollView addSubview:_favoriteButton];
    [self updateFavoriteButton];
    if (_track.appleMusicUrl.length) {
        _appleMusicButton = [self createActionButtonWithTitle:L(@"OPEN_IN_APPLE_MUSIC") tint:[SZTheme shazamBlue] action:@selector(openAppleMusic)];
        [_scrollView addSubview:_appleMusicButton];
    }

    // Player action buttons
    _muzikaButton = [self createActionButtonWithTitle:L(@"PLAY_IN_MUZIKA")
                                                 tint:[UIColor colorWithRed:0.85 green:0.15 blue:0.15 alpha:1.0]
                                               action:@selector(openMuzika)];
    [_scrollView addSubview:_muzikaButton];

    _spot6Button = [self createActionButtonWithTitle:L(@"PLAY_IN_SPOT6")
                                                tint:[UIColor colorWithRed:0.18 green:0.65 blue:0.15 alpha:1.0]
                                              action:@selector(openSpot6)];
    [_scrollView addSubview:_spot6Button];

    _tubieButton = [self createActionButtonWithTitle:L(@"SEARCH_IN_TUBIE")
                                                tint:[UIColor colorWithRed:0.75 green:0.20 blue:0.20 alpha:1.0]
                                              action:@selector(openTubie)];
    [_scrollView addSubview:_tubieButton];

    // Lyrics button if lyrics available
    if (_track.lyricsLines.count > 0) {
        _lyricsButton = [self createActionButtonWithTitle:L(@"LYRICS")
                                                     tint:[SZTheme shazamBlue]
                                                   action:@selector(openLyrics)];
        [_scrollView addSubview:_lyricsButton];
    }

    [self loadCoverArt];
}

- (UIButton *)createActionButtonWithTitle:(NSString *)title tint:(UIColor *)tint action:(SEL)sel
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    btn.titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    btn.titleLabel.shadowOffset = CGSizeMake(0, -1);

    UIImage *btnBg = [SZTheme glossyButtonWithColor:tint height:42.0 cornerRadius:8.0];
    [btn setBackgroundImage:btnBg forState:UIControlStateNormal];
    [btn addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

- (void)loadCoverArt
{
    if (_track.coverArtImage) {
        _coverImageView.image = _track.coverArtImage;
        return;
    }

    if (!_track.coverArtUrl.length) {
        _coverImageView.image = [UIImage imageNamed:@"Icon-72@2x.png"];
        return;
    }

    [_imageSpinner startAnimating];
    __weak typeof(self) weakSelf = self;
    [[SZShazamClient sharedClient] fetchCoverImageForTrack:_track completion:^(UIImage *img) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        [strongSelf->_imageSpinner stopAnimating];
        if (img) {
            strongSelf->_coverImageView.image = img;
            strongSelf->_coverImageView.alpha = 0.0;
            [UIView animateWithDuration:0.25 animations:^{
                strongSelf->_coverImageView.alpha = 1.0;
            }];
        }
    }];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    CGRect bounds = self.view.bounds;
    CGFloat width = bounds.size.width;

    CGFloat coverSize = SZIsPad() ? 240.0f : 170.0f;
    _coverImageView.frame = CGRectMake((width - coverSize) * 0.5f, 20.0f, coverSize, coverSize);
    _imageSpinner.center = CGPointMake(coverSize * 0.5f, coverSize * 0.5f);

    CGFloat y = CGRectGetMaxY(_coverImageView.frame) + 16.0f;
    CGFloat textWidth = width - 32.0f;

    CGFloat titleHeight = MAX(26.0f, [_titleLabel sizeThatFits:CGSizeMake(textWidth, CGFLOAT_MAX)].height);
    _titleLabel.frame = CGRectMake(16.0f, y, textWidth, titleHeight);
    y += titleHeight + 4.0f;

    _artistLabel.frame = CGRectMake(16.0f, y, textWidth, 22.0f);
    y += 24.0f;

    if (_albumLabel.text.length) {
        CGFloat detailsWidth = MIN(textWidth, 320.0f);
        CGFloat detailsHeight = [_albumLabel sizeThatFits:CGSizeMake(detailsWidth, CGFLOAT_MAX)].height;
        _albumLabel.frame = CGRectMake((width - detailsWidth) * 0.5f, y, detailsWidth, detailsHeight);
        y += detailsHeight + 12.0f;
    }

    y += 8.0f;
    CGFloat btnWidth = SZIsPad() ? 320.0f : (width - 40.0f);
    CGFloat btnX = (width - btnWidth) * 0.5f;

    _favoriteButton.frame = CGRectMake(btnX, y, btnWidth, 42.0f);
    y += 48.0f;
    if (_appleMusicButton) {
        _appleMusicButton.frame = CGRectMake(btnX, y, btnWidth, 42.0f);
        y += 48.0f;
    }

    _muzikaButton.frame = CGRectMake(btnX, y, btnWidth, 42.0f);
    y += 48.0f;

    _spot6Button.frame = CGRectMake(btnX, y, btnWidth, 42.0f);
    y += 48.0f;

    _tubieButton.frame = CGRectMake(btnX, y, btnWidth, 42.0f);
    y += 48.0f;

    if (_lyricsButton) {
        _lyricsButton.frame = CGRectMake(btnX, y, btnWidth, 42.0f);
        y += 52.0f;
    }

    _scrollView.contentSize = CGSizeMake(width, y + 24.0f);
}

- (void)openMuzika
{
    [SZUtils openInMuzika:_track];
}

- (void)updateFavoriteButton
{
    [_favoriteButton setTitle:_track.favorite ? L(@"REMOVE_FAVORITE") : L(@"ADD_FAVORITE") forState:UIControlStateNormal];
    _favoriteButton.accessibilityLabel = _track.favorite ? L(@"REMOVE_FAVORITE") : L(@"ADD_FAVORITE");
}

- (void)toggleFavorite
{
    [[SZHistoryStore sharedStore] setFavorite:!_track.favorite forTrack:_track];
    [self updateFavoriteButton];
}

- (void)openAppleMusic
{
    [SZUtils openInSafari:_track];
}

- (void)openSpot6
{
    [SZUtils openInSpot6:_track];
}

- (void)openTubie
{
    [SZUtils openInTubie:_track];
}

- (void)openLyrics
{
    if (_track.lyricsLines.count > 0) {
        SZLyricsViewController *vc = [[SZLyricsViewController alloc] initWithTrack:_track];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)shareTapped
{
    NSString *text = [NSString stringWithFormat:L(@"SHARE_TEXT"), _track.title, _track.artist];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    if ([UIActivityViewController class]) {
        NSMutableArray *items = [NSMutableArray arrayWithObject:text];
        if (_track.coverArtImage) [items addObject:_track.coverArtImage];
        if (_track.appleMusicUrl.length) [items addObject:[NSURL URLWithString:_track.appleMusicUrl]];

        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
        if (SZIsPad()) {
            if ([avc respondsToSelector:@selector(popoverPresentationController)]) {
                UIPopoverPresentationController *pop = avc.popoverPresentationController;
                pop.barButtonItem = self.navigationItem.rightBarButtonItem;
                [self presentViewController:avc animated:YES completion:nil];
            } else if ([UIPopoverController class]) {
                _activityPopover = [[UIPopoverController alloc] initWithContentViewController:avc];
                [_activityPopover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem
                                         permittedArrowDirections:UIPopoverArrowDirectionAny
                                                         animated:YES];
            } else {
                [self presentViewController:avc animated:YES completion:nil];
            }
        } else {
            [self presentViewController:avc animated:YES completion:nil];
        }
    } else {
        UIActionSheet *sheet = [[RetroActionSheet alloc] initWithTitle:text
                                                           delegate:self
                                                  cancelButtonTitle:L(@"CANCEL")
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:L(@"OPEN_IN_YOUTUBE"), L(@"OPEN_IN_SPOTIFY"), nil];
        [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    }
#pragma clang diagnostic pop
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [SZUtils openInTubie:_track];
    } else if (buttonIndex == 1) {
        [SZUtils openInSpot6:_track];
    }
}

@end
