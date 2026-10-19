#import "SZUtils.h"
#import "SZSettings.h"
#import "SZCommon.h"

@implementation SZUtils

+ (NSString *)urlEncode:(NSString *)string
{
    if (!string.length) return @"";
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (__bridge CFStringRef)string,
        NULL,
        CFSTR(":/?#[]@!$&'()*+,;="),
        kCFStringEncodingUTF8
    );
}

+ (BOOL)canOpenMuzika
{
    UIApplication *app = [UIApplication sharedApplication];
    return [app canOpenURL:[NSURL URLWithString:@"muzika://"]];
}

+ (BOOL)canOpenSpot6
{
    UIApplication *app = [UIApplication sharedApplication];
    return [app canOpenURL:[NSURL URLWithString:@"spotify://"]] ||
           [app canOpenURL:[NSURL URLWithString:@"spot6://"]];
}

+ (BOOL)canOpenTubie
{
    UIApplication *app = [UIApplication sharedApplication];
    return [app canOpenURL:[NSURL URLWithString:@"tubie://"]] ||
           [app canOpenURL:[NSURL URLWithString:@"youtube://"]];
}

+ (void)openInMuzika:(SZTrack *)track
{
    UIApplication *app = [UIApplication sharedApplication];
    NSString *query = [NSString stringWithFormat:@"%@ %@", track.title ?: @"", track.artist ?: @""];
    NSString *encoded = [self urlEncode:query];

    /* Try direct ISRC search if available */
    if (track.isrc.length) {
        NSURL *isrcUrl = [NSURL URLWithString:[NSString stringWithFormat:@"muzika://isrc/%@", track.isrc]];
        if ([app canOpenURL:isrcUrl]) {
            [app openURL:isrcUrl];
            return;
        }
    }

    NSURL *searchUrl = [NSURL URLWithString:[NSString stringWithFormat:@"muzika://search?q=%@", encoded]];
    if ([app canOpenURL:searchUrl]) {
        [app openURL:searchUrl];
        return;
    }

    /* Fallback to web YouTube Music */
    NSURL *webUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://music.youtube.com/search?q=%@", encoded]];
    [app openURL:webUrl];
}

+ (void)openInSpot6:(SZTrack *)track
{
    UIApplication *app = [UIApplication sharedApplication];
    NSString *query = [NSString stringWithFormat:@"%@ %@", track.title ?: @"", track.artist ?: @""];
    NSString *encoded = [self urlEncode:query];

    NSURL *spotUrl = [NSURL URLWithString:[NSString stringWithFormat:@"spotify:search:%@", encoded]];
    if ([app canOpenURL:spotUrl]) {
        [app openURL:spotUrl];
        return;
    }

    /* Web fallback */
    NSURL *webUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://open.spotify.com/search/%@", encoded]];
    [app openURL:webUrl];
}

+ (void)openInTubie:(SZTrack *)track
{
    UIApplication *app = [UIApplication sharedApplication];
    NSString *query = [NSString stringWithFormat:@"%@ %@ audio", track.title ?: @"", track.artist ?: @""];
    NSString *encoded = [self urlEncode:query];

    NSURL *tubieUrl = [NSURL URLWithString:[NSString stringWithFormat:@"tubie://search?q=%@", encoded]];
    if ([app canOpenURL:tubieUrl]) {
        [app openURL:tubieUrl];
        return;
    }

    NSURL *ytAppUrl = [NSURL URLWithString:[NSString stringWithFormat:@"youtube://results?search_query=%@", encoded]];
    if ([app canOpenURL:ytAppUrl]) {
        [app openURL:ytAppUrl];
        return;
    }

    /* Web fallback */
    NSURL *webUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.youtube.com/results?search_query=%@", encoded]];
    [app openURL:webUrl];
}

+ (void)openInSafari:(SZTrack *)track
{
    UIApplication *app = [UIApplication sharedApplication];
    if (track.appleMusicUrl.length) {
        NSURL *u = [NSURL URLWithString:track.appleMusicUrl];
        if (u) {
            [app openURL:u];
            return;
        }
    }
    NSString *query = [NSString stringWithFormat:@"%@ %@", track.title ?: @"", track.artist ?: @""];
    NSString *encoded = [self urlEncode:query];
    NSURL *web = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/search?q=%@", encoded]];
    [app openURL:web];
}

+ (void)openTrack:(SZTrack *)track inPlayer:(NSInteger)playerIndex
{
    switch ((SZPreferredPlayer)playerIndex) {
        case SZPreferredPlayerMuzika:
            [self openInMuzika:track];
            break;
        case SZPreferredPlayerSpot6:
            [self openInSpot6:track];
            break;
        case SZPreferredPlayerTubie:
            [self openInTubie:track];
            break;
        case SZPreferredPlayerSafari:
        default:
            [self openInSafari:track];
            break;
    }
}

+ (NSString *)formattedDate:(NSDate *)date
{
    if (!date) return @"";
    static NSDateFormatter *df = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        df = [[NSDateFormatter alloc] init];
        [df setDateStyle:NSDateFormatterMediumStyle];
        [df setTimeStyle:NSDateFormatterShortStyle];
    });
    return [df stringFromDate:date];
}

@end
