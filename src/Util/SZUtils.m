#import "SZUtils.h"
#import "SZSettings.h"
#import "SZCommon.h"
#import "MusicHandoff.h"
#import <objc/message.h>

@implementation SZUtils

+ (BOOL)openURLWithoutBlocking:(NSURL *)url
{
    UIApplication *app = [UIApplication sharedApplication];
    if (!url || ![app canOpenURL:url]) return NO;
    // Leave the incoming URL/scene callback before launching another app.
    // The synchronous legacy API can deadlock that transition on modern iOS.
    dispatch_async(dispatch_get_main_queue(), ^{
        SEL selector = NSSelectorFromString(@"openURL:options:completionHandler:");
        if ([app respondsToSelector:selector]) {
            // Resolve dynamically so the iOS 5 build still uses the 9.3 SDK.
            ((void (*)(id, SEL, NSURL *, NSDictionary *, void (^)(BOOL)))objc_msgSend)
                (app, selector, url, @{}, nil);
        } else {
            [app openURL:url];
        }
    });
    return YES;
}

+ (BOOL)openServiceURL:(NSString *)value
{
    if (!value.length) return NO;
    NSURL *url = [NSURL URLWithString:value];
    NSString *scheme = [url.scheme lowercaseString];
    if (![@[@"http", @"https", @"spotify", @"youtube", @"music", @"itms", @"itmss"] containsObject:scheme]) return NO;
    UIApplication *app = [UIApplication sharedApplication];
    if (![scheme isEqualToString:@"http"] && ![scheme isEqualToString:@"https"] && ![app canOpenURL:url]) return NO;
    return [self openURLWithoutBlocking:url];
}

+ (NSString *)urlEncode:(NSString *)string
{
    if (!string.length) return @"";
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(
        NULL,
        (__bridge CFStringRef)string,
        NULL,
        CFSTR("%:/?#[]@!$&'()*+,;="),
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
    return [app canOpenURL:[NSURL URLWithString:@"sixify://"]] ||
           [app canOpenURL:[NSURL URLWithString:@"spotify://"]] ||
           [app canOpenURL:[NSURL URLWithString:@"spot6://"]];
}

+ (BOOL)canOpenTubie
{
    UIApplication *app = [UIApplication sharedApplication];
    return [app canOpenURL:[NSURL URLWithString:@"tubie://"]] ||
           [app canOpenURL:[NSURL URLWithString:@"youtube://"]];
}

+ (BOOL)handoffTrack:(SZTrack *)track toScheme:(NSString *)scheme directURL:(NSString *)direct
{
    UIApplication *app = [UIApplication sharedApplication];
    NSString *video = MHYouTubeID(direct), *spotify = MHSpotifyURI(direct);
    NSString *parameter = nil, *value = nil;
    if (([scheme isEqualToString:@"muzika"] || [scheme isEqualToString:@"tubie"]) && video.length) {
        parameter = @"url";
        value = [@"https://www.youtube.com/watch?v=" stringByAppendingString:video];
    } else if (([scheme isEqualToString:@"sixify"] || [scheme isEqualToString:@"spot6"]) && spotify.length) {
        parameter = @"uri"; value = spotify;
    }
    if (value.length) {
        // Existing releases already play these links; do not send them through a browser.
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://open?%@=%@", scheme, parameter, [self urlEncode:value]]];
        return [self openURLWithoutBlocking:url];
    }
    NSString *query = [NSString stringWithFormat:@"%@ %@%@", track.title ?: @"", track.artist ?: @"", [scheme isEqualToString:@"tubie"] ? @" audio" : @""];
    NSArray *keys = @[@"q", @"autoplay", @"title", @"artist", @"isrc", @"duration"];
    NSArray *values = @[query, @"1", track.title ?: @"", track.artist ?: @"", track.isrc ?: @"", [NSString stringWithFormat:@"%.0f", track.duration]];
    NSMutableArray *parts = [NSMutableArray array];
    for (NSUInteger i = 0; i < keys.count; i++) {
        [parts addObject:[NSString stringWithFormat:@"%@=%@", [keys objectAtIndex:i], [self urlEncode:[values objectAtIndex:i]]]];
    }
    // Older receivers show search results; upgraded receivers also resolve and play a confident match.
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@://search?%@", scheme, [parts componentsJoinedByString:@"&"]]];
    return [self openURLWithoutBlocking:url];
}

+ (void)openInMuzika:(SZTrack *)track
{
    if ([self handoffTrack:track toScheme:@"muzika" directURL:track.youtubeUrl]) return;
    NSString *query = [self urlEncode:[NSString stringWithFormat:@"%@ %@", track.title ?: @"", track.artist ?: @""]];
    [self openURLWithoutBlocking:[NSURL URLWithString:[@"https://music.youtube.com/search?q=" stringByAppendingString:query]]];
}

+ (void)openInSpot6:(SZTrack *)track
{
    // The sibling app owns sixify/spot6, not the official app's spotify scheme.
    if ([self handoffTrack:track toScheme:@"sixify" directURL:track.spotifyUrl]) return;
    if ([self handoffTrack:track toScheme:@"spot6" directURL:track.spotifyUrl]) return;
    if ([self openServiceURL:track.spotifyUrl]) return;
    NSString *query = [self urlEncode:[NSString stringWithFormat:@"%@ %@", track.title ?: @"", track.artist ?: @""]];
    if ([self openServiceURL:[@"spotify:search:" stringByAppendingString:query]]) return;
    [self openURLWithoutBlocking:[NSURL URLWithString:[@"https://open.spotify.com/search/" stringByAppendingString:query]]];
}

+ (void)openInTubie:(SZTrack *)track
{
    if ([self handoffTrack:track toScheme:@"tubie" directURL:track.youtubeUrl]) return;
    if ([self openServiceURL:track.youtubeUrl]) return;
    NSString *query = [self urlEncode:[NSString stringWithFormat:@"%@ %@ audio", track.title ?: @"", track.artist ?: @""]];
    if ([self openServiceURL:[@"youtube://results?search_query=" stringByAppendingString:query]]) return;
    [self openURLWithoutBlocking:[NSURL URLWithString:[@"https://www.youtube.com/results?search_query=" stringByAppendingString:query]]];
}

+ (void)openInSafari:(SZTrack *)track
{
    UIApplication *app = [UIApplication sharedApplication];
    if (track.appleMusicUrl.length) {
        if ([self openServiceURL:track.appleMusicUrl]) return;
    }
    NSString *query = [NSString stringWithFormat:@"%@ %@", track.title ?: @"", track.artist ?: @""];
    NSString *encoded = [self urlEncode:query];
    NSURL *web = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.google.com/search?q=%@", encoded]];
    [self openURLWithoutBlocking:web];
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
