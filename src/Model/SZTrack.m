#import "SZTrack.h"
#import "SZCommon.h"

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
    t.trackId = [NSString stringWithFormat:@"%@", [trackDict objectForKey:@"key"] ?: [trackDict objectForKey:@"id"] ?: @""];
    t.title = [[trackDict objectForKey:@"title"] description] ?: @"Unknown Title";
    t.artist = [[trackDict objectForKey:@"subtitle"] description] ?: @"Unknown Artist";

    NSDictionary *images = [trackDict objectForKey:@"images"];
    if ([images isKindOfClass:[NSDictionary class]]) {
        t.coverArtUrl = [images objectForKey:@"coverart"] ?: [images objectForKey:@"background"];
    }

    NSArray *sections = [trackDict objectForKey:@"sections"];
    if ([sections isKindOfClass:[NSArray class]]) {
        for (NSDictionary *section in sections) {
            if (![section isKindOfClass:[NSDictionary class]]) continue;
            NSString *type = [section objectForKey:@"type"];

            if ([type isEqualToString:@"SONG"]) {
                NSArray *meta = [section objectForKey:@"metadata"];
                if ([meta isKindOfClass:[NSArray class]]) {
                    for (NSDictionary *item in meta) {
                        if (![item isKindOfClass:[NSDictionary class]]) continue;
                        NSString *title = [item objectForKey:@"title"];
                        NSString *text = [item objectForKey:@"text"];
                        if ([title isEqualToString:@"Album"]) t.album = text;
                        else if ([title isEqualToString:@"Released"]) t.releaseDate = text;
                        else if ([title isEqualToString:@"Label"]) t.label = text;
                    }
                }
            } else if ([type isEqualToString:@"LYRICS"]) {
                NSArray *text = [section objectForKey:@"text"];
                if ([text isKindOfClass:[NSArray class]]) {
                    t.lyricsLines = text;
                }
            }
        }
    }

    /* Genres */
    NSDictionary *genres = [trackDict objectForKey:@"genres"];
    if ([genres isKindOfClass:[NSDictionary class]] && [genres objectForKey:@"primary"]) {
        t.genre = [[genres objectForKey:@"primary"] description];
    }

    /* ISRC */
    t.isrc = [[trackDict objectForKey:@"isrc"] description];

    /* External URLs */
    t.appleMusicUrl = [[trackDict objectForKey:@"url"] description];
    NSDictionary *hub = [trackDict objectForKey:@"hub"];
    if ([hub isKindOfClass:[NSDictionary class]]) {
        NSDictionary *options = [hub objectForKey:@"options"];
        if ([options isKindOfClass:[NSArray class]] && [(NSArray *)options count]) {
            NSDictionary *firstOpt = SZFirst((NSArray *)options);
            if ([firstOpt isKindOfClass:[NSDictionary class]] && [firstOpt objectForKey:@"actions"]) {
                for (NSDictionary *act in [firstOpt objectForKey:@"actions"]) {
                    if ([[act objectForKey:@"type"] isEqualToString:@"uri"] && [act objectForKey:@"uri"]) {
                        t.appleMusicUrl = [act objectForKey:@"uri"];
                    }
                }
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
        _trackId = [[dict objectForKey:@"trackId"] copy];
        _title = [[dict objectForKey:@"title"] copy];
        _artist = [[dict objectForKey:@"artist"] copy];
        _album = [[dict objectForKey:@"album"] copy];
        _genre = [[dict objectForKey:@"genre"] copy];
        _releaseDate = [[dict objectForKey:@"releaseDate"] copy];
        _label = [[dict objectForKey:@"label"] copy];
        _coverArtUrl = [[dict objectForKey:@"coverArtUrl"] copy];
        _lyricsLines = [[dict objectForKey:@"lyricsLines"] copy];
        _appleMusicUrl = [[dict objectForKey:@"appleMusicUrl"] copy];
        _youtubeUrl = [[dict objectForKey:@"youtubeUrl"] copy];
        _spotifyUrl = [[dict objectForKey:@"spotifyUrl"] copy];
        _isrc = [[dict objectForKey:@"isrc"] copy];
        _pendingSignatureURI = [[dict objectForKey:@"pendingSignatureURI"] copy];

        NSNumber *ts = [dict objectForKey:@"timestamp"];
        if (ts) {
            _tagDate = [NSDate dateWithTimeIntervalSince1970:[ts doubleValue]];
        } else {
            _tagDate = [NSDate date];
        }

        NSData *imgData = [dict objectForKey:@"coverArtImageData"];
        if (imgData.length) {
            _coverArtImage = [UIImage imageWithData:imgData];
        }
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
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
