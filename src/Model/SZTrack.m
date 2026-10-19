#import "SZTrack.h"

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

    NSDictionary *trackDict = json[@"track"];
    if (![trackDict isKindOfClass:[NSDictionary class]]) {
        /* Direct track payload fallback */
        if (json[@"title"] && json[@"subtitle"]) {
            trackDict = json;
        } else {
            return nil;
        }
    }

    SZTrack *t = [[SZTrack alloc] init];
    t.trackId = [NSString stringWithFormat:@"%@", trackDict[@"key"] ?: trackDict[@"id"] ?: @""];
    t.title = [trackDict[@"title"] description] ?: @"Unknown Title";
    t.artist = [trackDict[@"subtitle"] description] ?: @"Unknown Artist";

    NSDictionary *images = trackDict[@"images"];
    if ([images isKindOfClass:[NSDictionary class]]) {
        t.coverArtUrl = images[@"coverart"] ?: images[@"background"];
    }

    NSArray *sections = trackDict[@"sections"];
    if ([sections isKindOfClass:[NSArray class]]) {
        for (NSDictionary *section in sections) {
            if (![section isKindOfClass:[NSDictionary class]]) continue;
            NSString *type = section[@"type"];

            if ([type isEqualToString:@"SONG"]) {
                NSArray *meta = section[@"metadata"];
                if ([meta isKindOfClass:[NSArray class]]) {
                    for (NSDictionary *item in meta) {
                        if (![item isKindOfClass:[NSDictionary class]]) continue;
                        NSString *title = item[@"title"];
                        NSString *text = item[@"text"];
                        if ([title isEqualToString:@"Album"]) t.album = text;
                        else if ([title isEqualToString:@"Released"]) t.releaseDate = text;
                        else if ([title isEqualToString:@"Label"]) t.label = text;
                    }
                }
            } else if ([type isEqualToString:@"LYRICS"]) {
                NSArray *text = section[@"text"];
                if ([text isKindOfClass:[NSArray class]]) {
                    t.lyricsLines = text;
                }
            }
        }
    }

    /* Genres */
    NSDictionary *genres = trackDict[@"genres"];
    if ([genres isKindOfClass:[NSDictionary class]] && genres[@"primary"]) {
        t.genre = [genres[@"primary"] description];
    }

    /* ISRC */
    t.isrc = [trackDict[@"isrc"] description];

    /* External URLs */
    t.appleMusicUrl = [trackDict[@"url"] description];
    NSDictionary *hub = trackDict[@"hub"];
    if ([hub isKindOfClass:[NSDictionary class]]) {
        NSDictionary *options = hub[@"options"];
        if ([options isKindOfClass:[NSArray class]] && [(NSArray *)options count]) {
            NSDictionary *firstOpt = [(NSArray *)options firstObject];
            if ([firstOpt isKindOfClass:[NSDictionary class]] && firstOpt[@"actions"]) {
                for (NSDictionary *act in firstOpt[@"actions"]) {
                    if ([act[@"type"] isEqualToString:@"uri"] && act[@"uri"]) {
                        t.appleMusicUrl = act[@"uri"];
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
        _trackId = [dict[@"trackId"] copy];
        _title = [dict[@"title"] copy];
        _artist = [dict[@"artist"] copy];
        _album = [dict[@"album"] copy];
        _genre = [dict[@"genre"] copy];
        _releaseDate = [dict[@"releaseDate"] copy];
        _label = [dict[@"label"] copy];
        _coverArtUrl = [dict[@"coverArtUrl"] copy];
        _lyricsLines = [dict[@"lyricsLines"] copy];
        _appleMusicUrl = [dict[@"appleMusicUrl"] copy];
        _youtubeUrl = [dict[@"youtubeUrl"] copy];
        _spotifyUrl = [dict[@"spotifyUrl"] copy];
        _isrc = [dict[@"isrc"] copy];
        _pendingSignatureURI = [dict[@"pendingSignatureURI"] copy];

        NSNumber *ts = dict[@"timestamp"];
        if (ts) {
            _tagDate = [NSDate dateWithTimeIntervalSince1970:[ts doubleValue]];
        } else {
            _tagDate = [NSDate date];
        }

        NSData *imgData = dict[@"coverArtImageData"];
        if (imgData.length) {
            _coverArtImage = [UIImage imageWithData:imgData];
        }
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSMutableDictionary *d = [NSMutableDictionary dictionary];
    if (_trackId) d[@"trackId"] = _trackId;
    if (_title) d[@"title"] = _title;
    if (_artist) d[@"artist"] = _artist;
    if (_album) d[@"album"] = _album;
    if (_genre) d[@"genre"] = _genre;
    if (_releaseDate) d[@"releaseDate"] = _releaseDate;
    if (_label) d[@"label"] = _label;
    if (_coverArtUrl) d[@"coverArtUrl"] = _coverArtUrl;
    if (_lyricsLines) d[@"lyricsLines"] = _lyricsLines;
    if (_appleMusicUrl) d[@"appleMusicUrl"] = _appleMusicUrl;
    if (_youtubeUrl) d[@"youtubeUrl"] = _youtubeUrl;
    if (_spotifyUrl) d[@"spotifyUrl"] = _spotifyUrl;
    if (_isrc) d[@"isrc"] = _isrc;
    if (_pendingSignatureURI) d[@"pendingSignatureURI"] = _pendingSignatureURI;
    if (_tagDate) d[@"timestamp"] = @([_tagDate timeIntervalSince1970]);

    if (_coverArtImage) {
        NSData *png = UIImagePNGRepresentation(_coverArtImage);
        if (png.length) d[@"coverArtImageData"] = png;
    }
    return d;
}

@end
