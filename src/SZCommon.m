// SZCommon.m - Implementation of common helpers and notification constants.
#import "SZCommon.h"

NSString * const SZThemeDidChangeNotification = @"SZThemeDidChangeNotification";
NSString * const SZSettingsDidChangeNotification = @"SZSettingsDidChangeNotification";
NSString * const SZHistoryDidChangeNotification = @"SZHistoryDidChangeNotification";
NSString * const SZErrorDomain = @"com.samcejko.shazamer.error";

NSError *SZMakeError(NSInteger code, NSString *message)
{
    NSDictionary *info = message ? @{ NSLocalizedDescriptionKey: message } : @{};
    return [NSError errorWithDomain:SZErrorDomain code:code userInfo:info];
}
