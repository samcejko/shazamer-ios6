#import "SZLyricsViewController.h"
#import "SZTheme.h"
#import "SZCommon.h"
#import "SZModern.h"

@interface SZLyricsViewController () {
    UITextView *_textView;
}
@end

@implementation SZLyricsViewController

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
    self.title = L(@"LYRICS");
    self.view.backgroundColor = [SZTheme backgroundDark];

    _textView = [[UITextView alloc] initWithFrame:self.view.bounds];
    _textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _textView.backgroundColor = [UIColor clearColor];
    _textView.textColor = [SZTheme textPrimary];
    _textView.font = [UIFont systemFontOfSize:SZIsPad() ? 19.0f : 16.0f];
    _textView.editable = NO;

    NSMutableString *content = [NSMutableString string];
    if (_track.title.length) {
        [content appendFormat:@"%@\n", _track.title];
    }
    if (_track.artist.length) {
        [content appendFormat:@"%@\n\n", _track.artist];
    }
    if (_track.lyricsLines.count) {
        for (NSString *line in _track.lyricsLines) {
            [content appendFormat:@"%@\n", line];
        }
    } else {
        [content appendString:L(@"NO_LYRICS")];
    }

    _textView.text = content;
    [self.view addSubview:_textView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    UIEdgeInsets insets = SZSafeAreaInsets(self.view);
    _textView.frame = UIEdgeInsetsInsetRect(self.view.bounds, insets);
}

@end
