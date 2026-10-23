#import "SZTheme.h"
#import <QuartzCore/QuartzCore.h>

@implementation SZTheme

+ (UIColor *)shazamBlue
{
    return [UIColor colorWithRed:0.0f / 255.0f green:136.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)shazamDarkBlue
{
    return [UIColor colorWithRed:0.0f / 255.0f green:65.0f / 255.0f blue:140.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)backgroundDark
{
    return [UIColor colorWithRed:14.0f / 255.0f green:19.0f / 255.0f blue:28.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)cardBackground
{
    return [UIColor colorWithRed:24.0f / 255.0f green:32.0f / 255.0f blue:46.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)textPrimary
{
    return [UIColor whiteColor];
}

+ (UIColor *)textSecondary
{
    return [UIColor colorWithRed:175.0f / 255.0f green:190.0f / 255.0f blue:215.0f / 255.0f alpha:1.0f];
}

+ (UIColor *)accentCyan
{
    return [UIColor colorWithRed:56.0f / 255.0f green:190.0f / 255.0f blue:255.0f / 255.0f alpha:1.0f];
}

+ (UIImage *)navigationBarBackgroundImage
{
    CGFloat w = 4.0;
    CGFloat h = 44.0;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), YES, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGFloat components[8] = {
        0.05f, 0.22f, 0.44f, 1.0f, // Top deep glossy blue
        0.02f, 0.10f, 0.22f, 1.0f  // Bottom navy
    };
    CGFloat locations[2] = {0.0f, 1.0f};
    CGGradientRef grad = CGGradientCreateWithColorComponents(cs, components, locations, 2);
    CGContextDrawLinearGradient(ctx, grad, CGPointMake(0, 0), CGPointMake(0, h), 0);
    CGGradientRelease(grad);
    CGColorSpaceRelease(cs);

    // 1px top highlight
    CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 0.28);
    CGContextFillRect(ctx, CGRectMake(0, 0, w, 1));

    // 1px bottom shadow line
    CGContextSetRGBFillColor(ctx, 0.0, 0.0, 0.0, 0.7);
    CGContextFillRect(ctx, CGRectMake(0, h - 1, w, 1));

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [img resizableImageWithCapInsets:UIEdgeInsetsMake(0, 1, 0, 1)];
}

+ (UIImage *)glossyButtonWithColor:(UIColor *)tint height:(CGFloat)height cornerRadius:(CGFloat)radius
{
    CGFloat w = radius * 2.0 + 8.0;
    CGFloat h = height;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(w, h), NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();

    CGRect rect = CGRectMake(0, 0, w, h);
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:radius];
    [path addClip];

    // Background gradient based on tint
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    const CGFloat *c = CGColorGetComponents(tint.CGColor);
    CGFloat r = c[0], g = c[1], b = c[2];

    CGFloat comp[8] = {
        (CGFloat)fmin(1.0, r * 1.3), (CGFloat)fmin(1.0, g * 1.3), (CGFloat)fmin(1.0, b * 1.3), 1.0f,
        (CGFloat)(r * 0.7), (CGFloat)(g * 0.7), (CGFloat)(b * 0.7), 1.0f
    };
    CGFloat loc[2] = {0.0f, 1.0f};
    CGGradientRef grad = CGGradientCreateWithColorComponents(cs, comp, loc, 2);
    CGContextDrawLinearGradient(ctx, grad, CGPointMake(0, 0), CGPointMake(0, h), 0);
    CGGradientRelease(grad);

    // Top half gloss
    CGRect glossRect = CGRectMake(0, 0, w, h * 0.48);
    CGFloat glossComp[8] = {
        1.0f, 1.0f, 1.0f, 0.45f,
        1.0f, 1.0f, 1.0f, 0.08f
    };
    CGGradientRef glossGrad = CGGradientCreateWithColorComponents(cs, glossComp, loc, 2);
    CGContextDrawLinearGradient(ctx, glossGrad, CGPointMake(0, 0), CGPointMake(0, glossRect.size.height), 0);
    CGGradientRelease(glossGrad);
    CGColorSpaceRelease(cs);

    // Inner bevel border
    CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithWhite:1.0 alpha:0.3].CGColor);
    CGContextSetLineWidth(ctx, 1.0);
    CGRect strokeRect = CGRectInset(rect, 0.5, 0.5);
    UIBezierPath *strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect cornerRadius:radius];
    [strokePath stroke];

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    // A one-pixel stretch region keeps the rounded ends intact on iOS 5+.
    // resizableImageWithCapInsets: tiles by default, repeating the bevel.
    return [img stretchableImageWithLeftCapWidth:(NSInteger)(w * 0.5f)
                                  topCapHeight:(NSInteger)(h * 0.5f)];
}

+ (void)applyNavigationTheme:(UINavigationBar *)bar
{
    if (!bar) return;
    UIImage *bg = [self navigationBarBackgroundImage];
    if ([bar respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]) {
        [bar setBackgroundImage:bg forBarMetrics:UIBarMetricsDefault];
    }
    bar.barStyle = UIBarStyleBlackOpaque;
    bar.tintColor = [self shazamDarkBlue];

    NSDictionary *titleAttr = @{
        UITextAttributeTextColor: [UIColor whiteColor],
        UITextAttributeTextShadowColor: [UIColor colorWithWhite:0.0 alpha:0.6],
        UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
        UITextAttributeFont: [UIFont boldSystemFontOfSize:20.0]
    };
    bar.titleTextAttributes = titleAttr;
}

@end
