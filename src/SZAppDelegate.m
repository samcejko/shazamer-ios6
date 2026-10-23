#import "SZAppDelegate.h"
#import "SZMainViewController.h"
#import "SZTheme.h"
#import "SZModern.h"
#import "SZTLSSocket.h"
#import "SZHistoryStore.h"
#import "SZCommon.h"
#import "SZDebug.h"

@implementation SZAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /* Initialize modern iOS appearance shim (iOS 14-17 TrollStore / rootless) */
    SZModernSetUp(UIBarStyleBlackOpaque);

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    SZMainViewController *mainVC = [[SZMainViewController alloc] init];
    self.navigationController = [[UINavigationController alloc] initWithRootViewController:mainVC];
    [SZTheme applyNavigationTheme:self.navigationController.navigationBar];

    self.window.rootViewController = self.navigationController;
    [self.window makeKeyAndVisible];

    /* Warm up TLS and root certificates */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [SZTLSSocket warmUp];
        [[SZHistoryStore sharedStore] load];
    });

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if ([[url.scheme lowercaseString] isEqualToString:@"shazamer"]) {
        if (SZHandleDebugURL(url, self.window, self.navigationController)) return YES;
        UIViewController *top = self.navigationController.topViewController;
        if ([top isKindOfClass:[SZMainViewController class]]) {
            SZMainViewController *main = (SZMainViewController *)top;
            if ([url.host isEqualToString:@"tag"] || [url.path isEqualToString:@"/tag"]) {
                // Auto trigger tag
                [main performSelector:@selector(tagButtonTapped) withObject:nil afterDelay:0.1];
            }
        }
        return YES;
    }
    return NO;
}

@end
