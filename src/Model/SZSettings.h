#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, SZPreferredPlayer) {
    SZPreferredPlayerMuzika = 0,
    SZPreferredPlayerSpot6  = 1,
    SZPreferredPlayerTubie  = 2,
    SZPreferredPlayerSafari = 3,
};

@interface SZSettings : NSObject

@property (nonatomic) BOOL autoListenOnLaunch;
@property (nonatomic) BOOL vibrateOnMatch;
@property (nonatomic) NSTimeInterval listenDuration;
@property (nonatomic) SZPreferredPlayer preferredPlayer;
@property (nonatomic) BOOL verifyTLS;

+ (instancetype)sharedSettings;
- (void)save;

@end
