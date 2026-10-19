#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SZTrack.h"

@interface SZUtils : NSObject

+ (void)openTrack:(SZTrack *)track inPlayer:(NSInteger)playerIndex;
+ (void)openInMuzika:(SZTrack *)track;
+ (void)openInSpot6:(SZTrack *)track;
+ (void)openInTubie:(SZTrack *)track;
+ (void)openInSafari:(SZTrack *)track;

+ (BOOL)canOpenMuzika;
+ (BOOL)canOpenSpot6;
+ (BOOL)canOpenTubie;

+ (NSString *)formattedDate:(NSDate *)date;

@end
