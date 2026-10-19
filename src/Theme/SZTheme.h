#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SZTheme : NSObject

+ (UIColor *)shazamBlue;
+ (UIColor *)shazamDarkBlue;
+ (UIColor *)backgroundDark;
+ (UIColor *)cardBackground;
+ (UIColor *)textPrimary;
+ (UIColor *)textSecondary;
+ (UIColor *)accentCyan;

+ (UIImage *)navigationBarBackgroundImage;
+ (UIImage *)glossyButtonWithColor:(UIColor *)tint height:(CGFloat)height cornerRadius:(CGFloat)radius;

+ (void)applyNavigationTheme:(UINavigationBar *)bar;

@end
