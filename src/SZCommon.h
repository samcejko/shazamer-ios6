// SZCommon.h - Shared macros, constants and notifications for Shazamer iOS 6.
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma clang diagnostic error "-Wunguarded-availability"

#define L(key) NSLocalizedString((key), nil)
#define SZIsPad() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define SZLog(fmt, ...) NSLog((@"[Shazamer] " fmt), ##__VA_ARGS__)

static inline void SZMain(dispatch_block_t block)
{
    if ([NSThread isMainThread]) block();
    else dispatch_async(dispatch_get_main_queue(), block);
}

extern NSString * const SZThemeDidChangeNotification;
extern NSString * const SZSettingsDidChangeNotification;
extern NSString * const SZHistoryDidChangeNotification;
extern NSString * const SZErrorDomain;

enum {
    SZErrorNetwork       = -1,
    SZErrorTLS           = -2,
    SZErrorCertificate   = -3,
    SZErrorTimeout       = -4,
    SZErrorCancelled     = -5,
    SZErrorBadResponse   = -6,
    SZErrorNoMatch       = -7,
    SZErrorMicDenied     = -8,
};

NSError *SZMakeError(NSInteger code, NSString *message);
