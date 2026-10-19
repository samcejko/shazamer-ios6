#import "SZShazamClient.h"
#import "SZHTTPRequest.h"
#import "SZCommon.h"

@interface SZShazamClient () {
    SZHTTPRequest *_activeRequest;
    NSCache *_imageCache;
}
@end

@implementation SZShazamClient

+ (instancetype)sharedClient
{
    static SZShazamClient *s_client = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_client = [[SZShazamClient alloc] init];
    });
    return s_client;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _imageCache = [[NSCache alloc] init];
        _imageCache.countLimit = 50;
    }
    return self;
}

- (void)cancel
{
    if (_activeRequest) {
        [_activeRequest cancel];
        _activeRequest = nil;
    }
}

- (void)recognizeWithSignatureURI:(NSString *)signatureURI
                         sampleMs:(NSUInteger)sampleMs
                       completion:(void (^)(SZTrack *track, NSError *error))completion
{
    [self cancel];

    if (!signatureURI.length) {
        if (completion) completion(nil, SZMakeError(SZErrorBadResponse, @"Empty signature"));
        return;
    }

    CFUUIDRef u1 = CFUUIDCreate(NULL);
    CFStringRef uStr1 = CFUUIDCreateString(NULL, u1);
    NSString *uuid1 = [(__bridge NSString *)uStr1 uppercaseString];
    CFRelease(uStr1);
    CFRelease(u1);

    CFUUIDRef u2 = CFUUIDCreate(NULL);
    CFStringRef uStr2 = CFUUIDCreateString(NULL, u2);
    NSString *uuid2 = [(__bridge NSString *)uStr2 lowercaseString];
    CFRelease(uStr2);
    CFRelease(u2);

    NSString *path = [NSString stringWithFormat:
                      @"/discovery/v5/en/US/android/-/tag/%@/%@?sync=true&webv3=true&sampling=true&connected=&shazamapiversion=v3&sharehub=true&video=v3",
                      uuid1, uuid2];

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    uint64_t ts = (uint64_t)(now * 1000.0);
    NSString *tz = [[NSTimeZone localTimeZone] name] ?: @"Europe/Prague";

    NSDictionary *postDict = @{
        @"geolocation": @{
            @"altitude": @300,
            @"latitude": @45,
            @"longitude": @2
        },
        @"signature": @{
            @"samplems": @(sampleMs),
            @"timestamp": @(ts),
            @"uri": signatureURI
        },
        @"timestamp": @(ts),
        @"timezone": tz
    };

    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:postDict options:0 error:&jsonError];
    if (!body) {
        if (completion) completion(nil, jsonError);
        return;
    }

    SZHTTPRequest *req = [SZHTTPRequest requestWithMethod:@"POST" host:@"amp.shazam.com" path:path];
    req.port = 443;
    req.secure = YES;
    req.body = body;
    req.headers = @{
        @"Content-Type": @"application/json",
        @"Content-Language": @"en_US",
        @"User-Agent": @"Shazam/14.2.0 (iPhone; iOS 14.2; Scale/2.00)"
    };
    req.connectTimeout = 12.0;
    req.readTimeout = 20.0;

    __weak typeof(self) weakSelf = self;
    req.onComplete = ^(NSInteger status, NSData *respBody, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) return;

        strongSelf->_activeRequest = nil;

        if (error) {
            SZLog(@"Shazam request error: %@", error.localizedDescription);
            if (completion) completion(nil, error);
            return;
        }

        if (status == 429) {
            if (completion) completion(nil, SZMakeError(SZErrorNetwork, @"Rate-limited by Shazam. Please wait a moment."));
            return;
        }

        if (status != 200 || !respBody.length) {
            if (completion) completion(nil, SZMakeError(SZErrorNoMatch, L(@"NO_MATCH")));
            return;
        }

        NSError *parseError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:respBody options:0 error:&parseError];
        if (![json isKindOfClass:[NSDictionary class]]) {
            if (completion) completion(nil, SZMakeError(SZErrorNoMatch, L(@"NO_MATCH")));
            return;
        }

        SZTrack *track = [SZTrack trackFromShazamJSON:json];
        if (track && track.title.length && track.artist.length) {
            SZLog(@"Recognized track: \"%@\" by %@", track.title, track.artist);
            if (completion) completion(track, nil);
        } else {
            SZLog(@"Shazam returned response, but no track match was identified");
            if (completion) completion(nil, SZMakeError(SZErrorNoMatch, L(@"NO_MATCH")));
        }
    };

    _activeRequest = req;
    [req start];
}

- (void)fetchCoverImageForTrack:(SZTrack *)track
                     completion:(void (^)(UIImage *image))completion
{
    if (!track.coverArtUrl.length) {
        if (completion) completion(nil);
        return;
    }

    UIImage *cached = [_imageCache objectForKey:track.coverArtUrl];
    if (cached) {
        track.coverArtImage = cached;
        if (completion) completion(cached);
        return;
    }

    NSURL *url = [NSURL URLWithString:track.coverArtUrl];
    if (!url.host) {
        if (completion) completion(nil);
        return;
    }

    NSString *host = url.host;
    NSString *path = url.path;
    if (url.query.length) {
        path = [NSString stringWithFormat:@"%@?%@", path, url.query];
    }
    BOOL isHttps = [[url.scheme lowercaseString] isEqualToString:@"https"];

    SZHTTPRequest *req = [SZHTTPRequest requestWithMethod:@"GET" host:host path:path];
    req.port = isHttps ? 443 : 80;
    req.secure = isHttps;
    req.headers = @{
        @"User-Agent": @"Mozilla/5.0 (iPhone; CPU iPhone OS 6_1_3 like Mac OS X) AppleWebKit/536.26"
    };

    __weak typeof(self) weakSelf = self;
    req.onComplete = ^(NSInteger status, NSData *body, NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (status == 200 && body.length) {
            UIImage *img = [UIImage imageWithData:body];
            if (img) {
                track.coverArtImage = img;
                if (strongSelf) {
                    [strongSelf->_imageCache setObject:img forKey:track.coverArtUrl];
                }
                if (completion) completion(img);
                return;
            }
        }
        if (completion) completion(nil);
    };

    [req start];
}

@end
