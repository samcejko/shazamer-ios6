#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SZTrack : NSObject

@property (nonatomic, copy) NSString *trackId;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *artist;
@property (nonatomic, copy) NSString *album;
@property (nonatomic, copy) NSString *genre;
@property (nonatomic, copy) NSString *releaseDate;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *coverArtUrl;
@property (nonatomic, strong) UIImage *coverArtImage;
@property (nonatomic, copy) NSArray *lyricsLines;
@property (nonatomic, copy) NSString *appleMusicUrl;
@property (nonatomic, copy) NSString *youtubeUrl;
@property (nonatomic, copy) NSString *spotifyUrl;
@property (nonatomic, copy) NSString *isrc;
@property (nonatomic, strong) NSDate *tagDate;
@property (nonatomic, copy) NSString *pendingSignatureURI;

- (BOOL)isPendingOffline;

- (instancetype)initWithDictionary:(NSDictionary *)dict;
- (NSDictionary *)dictionaryRepresentation;

+ (instancetype)trackFromShazamJSON:(NSDictionary *)json;

@end
