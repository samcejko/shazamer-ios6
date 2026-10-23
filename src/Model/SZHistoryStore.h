#import <Foundation/Foundation.h>
#import "SZTrack.h"

@interface SZHistoryStore : NSObject

@property (nonatomic, readonly) NSArray *tracks;

+ (instancetype)sharedStore;

- (void)addTrack:(SZTrack *)track;
- (void)removeTrackAtIndex:(NSUInteger)index;
- (void)removeTrack:(SZTrack *)track;
- (void)setFavorite:(BOOL)favorite forTrack:(SZTrack *)track;
- (void)clearHistory;
- (void)save;
- (void)load;

- (SZTrack *)pendingOfflineTrack;
- (void)replacePendingTrack:(SZTrack *)pending withTrack:(SZTrack *)recognized;

@end
