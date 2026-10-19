#import "SZSettings.h"
#import "SZCommon.h"

static NSString * const kSZAutoListenKey = @"SZAutoListen";
static NSString * const kSZVibrateKey = @"SZVibrate";
static NSString * const kSZListenDurationKey = @"SZListenDuration";
static NSString * const kSZPreferredPlayerKey = @"SZPreferredPlayer";

@implementation SZSettings

+ (instancetype)sharedSettings
{
    static SZSettings *s_settings = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_settings = [[SZSettings alloc] init];
    });
    return s_settings;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        _autoListenOnLaunch = [ud boolForKey:kSZAutoListenKey];
        if ([ud objectForKey:kSZVibrateKey]) {
            _vibrateOnMatch = [ud boolForKey:kSZVibrateKey];
        } else {
            _vibrateOnMatch = YES;
        }

        double dur = [ud doubleForKey:kSZListenDurationKey];
        _listenDuration = (dur >= 3.0 && dur <= 12.0) ? dur : 6.0;

        _preferredPlayer = (SZPreferredPlayer)[ud integerForKey:kSZPreferredPlayerKey];
    }
    return self;
}

- (void)save
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:_autoListenOnLaunch forKey:kSZAutoListenKey];
    [ud setBool:_vibrateOnMatch forKey:kSZVibrateKey];
    [ud setDouble:_listenDuration forKey:kSZListenDurationKey];
    [ud setInteger:_preferredPlayer forKey:kSZPreferredPlayerKey];
    [ud synchronize];

    [[NSNotificationCenter defaultCenter] postNotificationName:SZSettingsDidChangeNotification object:self];
}

@end
