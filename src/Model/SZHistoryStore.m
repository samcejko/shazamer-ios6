#import "SZHistoryStore.h"
#import "SZCommon.h"

@interface SZHistoryStore () {
    NSMutableArray *_tracks;
}
@end

@implementation SZHistoryStore

+ (instancetype)sharedStore
{
    static SZHistoryStore *s_store = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_store = [[SZHistoryStore alloc] init];
    });
    return s_store;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _tracks = [NSMutableArray array];
        [self load];
    }
    return self;
}

- (NSArray *)tracks
{
    @synchronized(_tracks) {
        return [_tracks copy];
    }
}

- (NSString *)historyFilePath
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = SZFirst(paths);
    return [docDir stringByAppendingPathComponent:@"History.plist"];
}

- (void)load
{
    @synchronized(_tracks) {
        [_tracks removeAllObjects];
        NSString *path = [self historyFilePath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSArray *rawArray = [NSArray arrayWithContentsOfFile:path];
            if ([rawArray isKindOfClass:[NSArray class]]) {
                for (NSDictionary *d in rawArray) {
                    if ([d isKindOfClass:[NSDictionary class]]) {
                        SZTrack *t = [[SZTrack alloc] initWithDictionary:d];
                        if (t) [_tracks addObject:t];
                    }
                }
            }
        }
        SZLog(@"Loaded %lu tracks from history", (unsigned long)_tracks.count);
    }
}

- (void)save
{
    @synchronized(_tracks) {
        NSMutableArray *serialized = [NSMutableArray arrayWithCapacity:_tracks.count];
        for (SZTrack *t in _tracks) {
            [serialized addObject:[t dictionaryRepresentation]];
        }
        NSString *path = [self historyFilePath];
        [serialized writeToFile:path atomically:YES];
        SZLog(@"Saved %lu tracks to history", (unsigned long)_tracks.count);
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:SZHistoryDidChangeNotification object:self];
}

- (void)addTrack:(SZTrack *)track
{
    if (!track) return;
    @synchronized(_tracks) {
        /* Avoid duplicate if same track was tagged within last 10 minutes */
        if (track.trackId.length) {
            for (SZTrack *existing in _tracks) {
                if ([existing.trackId isEqualToString:track.trackId]) {
                    NSTimeInterval diff = [track.tagDate timeIntervalSinceDate:existing.tagDate];
                    if (fabs(diff) < 600.0) {
                        return;
                    }
                }
            }
        }
        [_tracks insertObject:track atIndex:0];
    }
    [self save];
}

- (void)removeTrackAtIndex:(NSUInteger)index
{
    @synchronized(_tracks) {
        if (index < _tracks.count) {
            [_tracks removeObjectAtIndex:index];
        }
    }
    [self save];
}

- (void)clearHistory
{
    @synchronized(_tracks) {
        [_tracks removeAllObjects];
    }
    [self save];
}

- (SZTrack *)pendingOfflineTrack
{
    @synchronized(_tracks) {
        for (SZTrack *t in _tracks) {
            if ([t isPendingOffline]) return t;
        }
    }
    return nil;
}

- (void)replacePendingTrack:(SZTrack *)pending withTrack:(SZTrack *)recognized
{
    if (!pending || !recognized) return;
    @synchronized(_tracks) {
        NSUInteger idx = [_tracks indexOfObject:pending];
        if (idx != NSNotFound) {
            _tracks[idx] = recognized;
        } else {
            [_tracks insertObject:recognized atIndex:0];
        }
    }
    [self save];
}

@end
