#import "SZDebug.h"
#import "SZAudioRecorder.h"
#import "SZHistoryStore.h"
#import "SZMainViewController.h"
#import "SZTrackViewController.h"
#import "SZUtils.h"
#import <QuartzCore/QuartzCore.h>

@interface SZMainViewController (DebugActions)
- (void)openHistory;
- (void)openSettings;
@end
@interface SZTrackViewController (DebugActions)
- (void)toggleFavorite;
@end

static void SZCollectViews(UIView *view, NSMutableArray *views)
{
    [views addObject:view];
    for (UIView *child in view.subviews) SZCollectViews(child, views);
}

BOOL SZHandleDebugURL(NSURL *url, UIWindow *window, UINavigationController *navigation)
{
    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    if (![[NSFileManager defaultManager] fileExistsAtPath:[documents stringByAppendingPathComponent:@"debug"]]) return NO;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    for (NSString *part in [url.query componentsSeparatedByString:@"&"]) {
        NSRange equals = [part rangeOfString:@"="];
        if (equals.location == NSNotFound) continue;
        NSString *key = [[part substringToIndex:equals.location] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSString *value = [[part substringFromIndex:equals.location + 1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if (key && value) [params setObject:value forKey:key];
    }
    NSString *command = url.host;
    UIViewController *top = window.rootViewController;
    while (top.presentedViewController) top = top.presentedViewController;
    if ([top isKindOfClass:[UINavigationController class]]) top = [(UINavigationController *)top topViewController];
    if ([command isEqualToString:@"snapshot"]) {
        CGSize size = window.bounds.size;
        UIGraphicsBeginImageContextWithOptions(size, YES, 0);
        [window.layer renderInContext:UIGraphicsGetCurrentContext()];
        NSData *data = UIImagePNGRepresentation(UIGraphicsGetImageFromCurrentImageContext());
        UIGraphicsEndImageContext();
        [data writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"screen.png"] atomically:YES];
        return YES;
    }
    if ([command isEqualToString:@"status"]) {
        NSMutableArray *views = [NSMutableArray array], *labels = [NSMutableArray array], *tracks = [NSMutableArray array];
        SZCollectViews(window, views);
        for (UIView *view in views) if (!view.hidden && [view isKindOfClass:[UILabel class]] && ((UILabel *)view).text.length) [labels addObject:((UILabel *)view).text];
        for (SZTrack *track in [SZHistoryStore sharedStore].tracks) {
            [tracks addObject:@{@"title":track.title ?: @"", @"artist":track.artist ?: @"", @"favorite":@(track.favorite), @"pending":@([track isPendingOffline])}];
        }
        NSDictionary *status = @{@"screen":NSStringFromClass([top class]), @"recording":@([SZAudioRecorder sharedRecorder].isRecording), @"labels":labels, @"tracks":tracks};
        [[NSJSONSerialization dataWithJSONObject:status options:0 error:NULL] writeToFile:[NSTemporaryDirectory() stringByAppendingPathComponent:@"status.json"] atomically:YES];
        return YES;
    }
    if ([command isEqualToString:@"settings"] && [top isKindOfClass:[SZMainViewController class]]) { [(SZMainViewController *)top openSettings]; return YES; }
    if ([command isEqualToString:@"history"] && [top isKindOfClass:[SZMainViewController class]]) { [(SZMainViewController *)top openHistory]; return YES; }
    if ([command isEqualToString:@"back"]) {
        if (top.navigationController.viewControllers.count > 1) [top.navigationController popViewControllerAnimated:NO];
        else if (navigation.presentedViewController) [navigation dismissViewControllerAnimated:NO completion:nil];
        return YES;
    }
    if ([command isEqualToString:@"detail"]) {
        NSArray *tracks = [SZHistoryStore sharedStore].tracks;
        NSUInteger index = [[params objectForKey:@"index"] integerValue];
        if (index < tracks.count) [top.navigationController pushViewController:[[SZTrackViewController alloc] initWithTrack:[tracks objectAtIndex:index]] animated:NO];
        return YES;
    }
    if ([command isEqualToString:@"favorite"] && [top isKindOfClass:[SZTrackViewController class]]) { [(SZTrackViewController *)top toggleFavorite]; return YES; }
    if ([command isEqualToString:@"handoff"] && [top isKindOfClass:[SZTrackViewController class]]) {
        SZTrack *track = [(SZTrackViewController *)top track];
        NSString *app = [params objectForKey:@"app"];
        if ([app isEqualToString:@"muzika"]) [SZUtils openInMuzika:track];
        if ([app isEqualToString:@"sixify"]) [SZUtils openInSpot6:track];
        if ([app isEqualToString:@"tubie"]) [SZUtils openInTubie:track];
        return YES;
    }
    if ([command isEqualToString:@"search"] || [command isEqualToString:@"filter"]) {
        NSMutableArray *views = [NSMutableArray array]; SZCollectViews(top.view, views);
        for (UIView *view in views) {
            if ([command isEqualToString:@"search"] && [view isKindOfClass:[UISearchBar class]]) {
                UISearchBar *bar = (UISearchBar *)view; bar.text = [params objectForKey:@"q"] ?: @"";
                [bar.delegate searchBar:bar textDidChange:bar.text]; [bar resignFirstResponder];
            }
            if ([command isEqualToString:@"filter"] && [view isKindOfClass:[UISegmentedControl class]]) {
                ((UISegmentedControl *)view).selectedSegmentIndex = [[params objectForKey:@"favorites"] boolValue] ? 1 : 0;
                [(UIControl *)view sendActionsForControlEvents:UIControlEventValueChanged];
            }
        }
        return YES;
    }
    return NO;
}
