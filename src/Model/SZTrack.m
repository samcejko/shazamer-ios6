#import "SZTrack.h"
#import "SZCommon.h"
#include <math.h>

static NSString *SZTrackString(id value)
{
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

static NSTimeInterval SZTrackDuration(id value)
{
    if ([value isKindOfClass:[NSNumber class]]) return isfinite([value doubleValue]) ? MIN(86400.0, MAX(0, [value doubleValue])) : 0;
    if (![value isKindOfClass:[NSString class]]) return 0;
    NSArray *parts = [value componentsSeparatedByString:@":"];
    double seconds = 0;
    for (NSString *part in parts) seconds = seconds * 60 + [part doubleValue];
    return isfinite(seconds) ? MIN(86400.0, MAX(0, seconds)) : 0;
}

@implementation SZTrack

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tagDate = [NSDate date];
    }
    return self;
}

- (BOOL)isPendingOffline
{
    return (_pendingSignatureURI.length > 0 && !_title.length);
}

+ (instancetype)trackFromShazamJSON:(NSDictionary *)json
{
    if (![json isKindOfClass:[NSDictionary class]]) return nil;

    NSDictionary *trackDict = [json objectForKey:@"track"];
    if (![trackDict isKindOfClass:[NSDictionary class]]) {
        /* Direct track payload fallback */
        if ([json objectForKey:@"title"] && [json objectForKey:@"subtitle"]) {
            trackDict = json;
        } else {
            return nil;
        }
    }

    SZTrack *t = [[SZTrack alloc] init];
    id key = [trackDict objectForKey:@"key"] ?: [trackDict objectForKey:@"id"];
    t.trackId = [key isKindOfClass:[NSString class]] || [key isKindOfClass:[NSNumber class]] ? [key description] : @"";
    t.title = SZTrackString([trackDict objectForKey:@"title"]);
    t.artist = SZTrackString([trackDict objectForKey:@"subtitle"]);
    if (!t.title.length || !t.artist.length) return nil;
    t.duration = SZTrackDuration([trackDict objectForKey:@"duration"]);

    NSDictionary *images = [trackDict objectForKey:@"images"];
    if ([images isKindOfClass:[NSDictionary class]]) {
        t.coverArtUrl = SZTrackString([images objectForKey:@"coverart"]) ?: SZTrackString([images objectForKey:@"background"]);
    }

    NSArray *sections = [trackDict objectForKey:@"sections"];
    if ([sections isKindOfClass:[NSArray class]]) {
        for (NSDictionary *section in sections) {
            if (![section isKindOfClass:[NSDictionary class]]) continue;
            NSString *type = SZTrackString([section objectForKey:@"type"]);

            if ([type isEqualToString:@"SONG"]) {
                NSArray *meta = [section objectForKey:@"metadata"];
                if ([meta isKindOfClass:[NSArray class]]) {
                    for (NSDictionary *item in meta) {
                        if (![item isKindOfClass:[NSDictionary class]]) continue;
                        NSString *title = SZTrackString([item objectForKey:@"title"]);
                        NSString *text = SZTrackString([item objectForKey:@"text"]);
                        if ([title isEqualToString:@"Album"]) t.album = text;
                        else if ([title isEqualToString:@"Released"]) t.releaseDate = text;
                        else if ([title isEqualToString:@"Label"]) t.label = text;
                        else if ([title isEqualToString:@"Duration"]) t.duration = SZTrackDuration(text);
                    }
                }
            } else if ([type isEqualToString:@"LYRICS"]) {
                NSArray *text = [section objectForKey:@"text"];
                if ([text isKindOfClass:[NSArray class]]) {
                    NSMutableArray *lines = [NSMutableArray array];
                    for (id line in text) if (SZTrackString(line)) [lines addObject:line];
                    t.lyricsLines = lines;
                }
            }
        }
    }

    /* Genres */
    NSDictionary *genres = [trackDict objectForKey:@"genres"];
    if ([genres isKindOfClass:[NSDictionary class]] && [genres objectForKey:@"primary"]) {
        t.genre = SZTrackString([genres objectForKey:@"primary"]);
    }

    /* ISRC */
    t.isrc = SZTrackString([trackDict objectForKey:@"isrc"]);

    /* External URLs */
    // The top-level url is a Shazam page, not an Apple Music deep link.
    NSDictionary *hub = [trackDict objectForKey:@"hub"];
    if ([hub isKindOfClass:[NSDictionary class]]) {
        id options = [hub objectForKey:@"options"];
        if ([options isKindOfClass:[NSArray class]] && [(NSArray *)options count]) {
            NSDictionary *firstOpt = SZFirst((NSArray *)options);
            if ([firstOpt isKindOfClass:[NSDictionary class]] && [[firstOpt objectForKey:@"actions"] isKindOfClass:[NSArray class]]) {
                for (NSDictionary *act in [firstOpt objectForKey:@"actions"]) {
                    if ([act isKindOfClass:[NSDictionary class]] && [SZTrackString([act objectForKey:@"type"]) isEqualToString:@"uri"] && SZTrackString([act objectForKey:@"uri"])) {
                        t.appleMusicUrl = SZTrackString([act objectForKey:@"uri"]);
                    }
                }
            }
        }
        id providers = [hub objectForKey:@"providers"];
        if ([providers isKindOfClass:[NSArray class]]) for (id provider in providers) {
            if (![provider isKindOfClass:[NSDictionary class]]) continue;
            NSString *type = [SZTrackString([provider objectForKey:@"type"]) lowercaseString];
            id actions = [provider objectForKey:@"actions"];
            if (![actions isKindOfClass:[NSArray class]]) continue;
            for (id action in actions) {
                if (![action isKindOfClass:[NSDictionary class]]) continue;
                NSString *uri = SZTrackString([action objectForKey:@"uri"]);
                if (!uri.length) continue;
                if ([type isEqualToString:@"spotify"]) t.spotifyUrl = uri;
                if ([type isEqualToString:@"youtube"]) t.youtubeUrl = uri;
            }
        }
    }

    t.tagDate = [NSDate date];
    return t;
}

- (instancetype)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self && [dict isKindOfClass:[NSDictionary class]]) {
        _trackId = [SZTrackString([dict objectForKey:@"trackId"]) copy];
        _title = [SZTrackString([dict objectForKey:@"title"]) copy];
        _artist = [SZTrackString([dict objectForKey:@"artist"]) copy];
        _album = [SZTrackString([dict objectForKey:@"album"]) copy];
        _genre = [SZTrackString([dict objectForKey:@"genre"]) copy];
        _releaseDate = [SZTrackString([dict objectForKey:@"releaseDate"]) copy];
        _label = [SZTrackString([dict objectForKey:@"label"]) copy];
        _coverArtUrl = [SZTrackString([dict objectForKey:@"coverArtUrl"]) copy];
        id lines = [dict objectForKey:@"lyricsLines"];
        if ([lines isKindOfClass:[NSArray class]]) {
            NSMutableArray *safeLines = [NSMutableArray array];
            for (id line in lines) if (SZTrackString(line)) [safeLines addObject:line];
            _lyricsLines = [safeLines copy];
        }
        _appleMusicUrl = [SZTrackString([dict objectForKey:@"appleMusicUrl"]) copy];
        _youtubeUrl = [SZTrackString([dict objectForKey:@"youtubeUrl"]) copy];
        _spotifyUrl = [SZTrackString([dict objectForKey:@"spotifyUrl"]) copy];
        _isrc = [SZTrackString([dict objectForKey:@"isrc"]) copy];
        _pendingSignatureURI = [SZTrackString([dict objectForKey:@"pendingSignatureURI"]) copy];
        id favorite = [dict objectForKey:@"favorite"];
        _favorite = [favorite isKindOfClass:[NSNumber class]] && [favorite boolValue];
        _duration = SZTrackDuration([dict objectForKey:@"duration"]);
        NSNumber *sampleMs = [dict objectForKey:@"pendingSampleMs"];
        _pendingSampleMs = [sampleMs isKindOfClass:[NSNumber class]] ? [sampleMs unsignedIntegerValue] : 6000;

        NSNumber *ts = [dict objectForKey:@"timestamp"];
        if ([ts isKindOfClass:[NSNumber class]]) {
            _tagDate = [NSDate dateWithTimeIntervalSince1970:[ts doubleValue]];
        } else {
            _tagDate = [NSDate date];
        }

        NSData *imgData = [dict objectForKey:@"coverArtImageData"];
        if ([imgData isKindOfClass:[NSData class]] && imgData.length) {
            _coverArtImage = [UIImage imageWithData:imgData];
        }
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    [d setObject:@(_favorite) forKey:@"favorite"];
    [d setObject:@(_duration) forKey:@"duration"];
    [d setObject:@(_pendingSampleMs) forKey:@"pendingSampleMs"];
    if (_trackId) [d setObject:(_trackId) forKey:@"trackId"];
    if (_title) [d setObject:(_title) forKey:@"title"];
    if (_artist) [d setObject:(_artist) forKey:@"artist"];
    if (_album) [d setObject:(_album) forKey:@"album"];
    if (_genre) [d setObject:(_genre) forKey:@"genre"];
    if (_releaseDate) [d setObject:(_releaseDate) forKey:@"releaseDate"];
    if (_label) [d setObject:(_label) forKey:@"label"];
    if (_coverArtUrl) [d setObject:(_coverArtUrl) forKey:@"coverArtUrl"];
    if (_lyricsLines) [d setObject:(_lyricsLines) forKey:@"lyricsLines"];
    if (_appleMusicUrl) [d setObject:(_appleMusicUrl) forKey:@"appleMusicUrl"];
    if (_youtubeUrl) [d setObject:(_youtubeUrl) forKey:@"youtubeUrl"];
    if (_spotifyUrl) [d setObject:(_spotifyUrl) forKey:@"spotifyUrl"];
    if (_isrc) [d setObject:(_isrc) forKey:@"isrc"];
    if (_pendingSignatureURI) [d setObject:(_pendingSignatureURI) forKey:@"pendingSignatureURI"];
    if (_tagDate) [d setObject:(@([_tagDate timeIntervalSince1970])) forKey:@"timestamp"];

    if (_coverArtImage) {
        NSData *png = UIImagePNGRepresentation(_coverArtImage);
        if (png.length) [d setObject:(png) forKey:@"coverArtImageData"];
    }
    return d;
}

@end
