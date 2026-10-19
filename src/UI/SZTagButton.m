#import "SZTagButton.h"
#import "SZTheme.h"
#import <QuartzCore/QuartzCore.h>

@implementation SZTagButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.adjustsImageWhenHighlighted = NO;
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = highlighted ? CGAffineTransformMakeScale(0.94, 0.94) : CGAffineTransformIdentity;
    }];
}

- (void)startListeningPulse
{
    if (_isListening) return;
    _isListening = YES;

    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    pulse.duration = 0.9;
    pulse.fromValue = @(1.0);
    pulse.toValue = @(1.06);
    pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    pulse.autoreverses = YES;
    pulse.repeatCount = HUGE_VALF;
    [self.layer addAnimation:pulse forKey:@"sz_pulse"];
}

- (void)stopListeningPulse
{
    if (!_isListening) return;
    _isListening = NO;
    [self.layer removeAnimationForKey:@"sz_pulse"];
    [UIView animateWithDuration:0.2 animations:^{
        self.transform = CGAffineTransformIdentity;
    }];
}

static CGPathRef SZCreateShazamPath(CGRect rect)
{
    CGMutablePathRef path = CGPathCreateMutable();

    /* Target 24x24 box scaled and centered in rect */
    CGFloat s = rect.size.width / 24.0;
    CGAffineTransform t = CGAffineTransformMakeTranslation(rect.origin.x, rect.origin.y);
    t = CGAffineTransformScale(t, s, s);

    // Loop 1
    CGPathMoveToPoint(path, &t, 9.872, 16.736);
    CGPathAddCurveToPoint(path, &t, 8.585, 16.736, 7.299, 16.31, 6.311, 15.455);
    CGPathAddCurveToPoint(path, &t, 5.097, 14.406, 4.377, 12.976, 4.282, 11.431);
    CGPathAddCurveToPoint(path, &t, 4.192, 9.932, 4.702, 8.487, 5.718, 7.364);
    CGPathAddCurveToPoint(path, &t, 6.86, 6.101, 8.907, 4.139, 8.993, 4.055);
    CGPathAddCurveToPoint(path, &t, 9.548, 3.523, 10.428, 3.544, 10.959, 4.1);
    CGPathAddCurveToPoint(path, &t, 11.489, 4.657, 11.471, 5.539, 10.915, 6.071);
    CGPathAddCurveToPoint(path, &t, 10.894, 6.091, 8.854, 8.047, 7.778, 9.235);
    CGPathAddCurveToPoint(path, &t, 7.27, 9.799, 7.014, 10.518, 7.059, 11.262);
    CGPathAddCurveToPoint(path, &t, 7.108, 12.051, 7.487, 12.791, 8.129, 13.348);
    CGPathAddCurveToPoint(path, &t, 8.973, 14.078, 10.639, 14.239, 11.682, 13.305);
    CGPathAddCurveToPoint(path, &t, 12.301, 12.746, 13.054, 11.928, 13.062, 11.919);
    CGPathAddCurveToPoint(path, &t, 13.582, 11.352, 14.462, 11.316, 15.027, 11.837);
    CGPathAddCurveToPoint(path, &t, 15.592, 12.357, 15.63, 13.239, 15.11, 13.808);
    CGPathAddCurveToPoint(path, &t, 15.075, 13.843, 14.258, 14.732, 13.538, 15.38);
    CGPathAddCurveToPoint(path, &t, 12.533, 16.282, 11.202, 16.736, 9.872, 16.736);
    CGPathCloseSubpath(path);

    // Loop 2
    CGPathMoveToPoint(path, &t, 18.282, 16.637);
    CGPathAddCurveToPoint(path, &t, 17.139, 17.899, 15.093, 19.862, 15.006, 19.946);
    CGPathAddCurveToPoint(path, &t, 14.736, 20.202, 14.391, 20.331, 14.046, 20.331);
    CGPathAddCurveToPoint(path, &t, 13.678, 20.331, 13.314, 20.186, 13.04, 19.901);
    CGPathAddCurveToPoint(path, &t, 12.509, 19.342, 12.528, 18.462, 13.084, 17.93);
    CGPathAddCurveToPoint(path, &t, 13.105, 17.91, 15.147, 15.953, 16.221, 14.764);
    CGPathAddCurveToPoint(path, &t, 16.729, 14.201, 16.985, 13.481, 16.94, 12.737);
    CGPathAddCurveToPoint(path, &t, 16.892, 11.948, 16.512, 11.208, 15.87, 10.654);
    CGPathAddCurveToPoint(path, &t, 15.026, 9.924, 13.36, 9.761, 12.318, 10.698);
    CGPathAddCurveToPoint(path, &t, 11.697, 11.254, 10.945, 12.074, 10.938, 12.082);
    CGPathAddCurveToPoint(path, &t, 10.417, 12.648, 9.539, 12.686, 8.972, 12.166);
    CGPathAddCurveToPoint(path, &t, 8.408, 11.645, 8.368, 10.762, 8.89, 10.195);
    CGPathAddCurveToPoint(path, &t, 8.924, 10.158, 9.74, 9.269, 10.461, 8.622);
    CGPathAddCurveToPoint(path, &t, 12.44, 6.844, 15.682, 6.809, 17.688, 8.545);
    CGPathAddCurveToPoint(path, &t, 18.902, 9.596, 19.623, 11.025, 19.716, 12.57);
    CGPathAddCurveToPoint(path, &t, 19.808, 14.067, 19.297, 15.515, 18.282, 16.637);
    CGPathCloseSubpath(path);

    return path;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGRect bounds = self.bounds;
    CGPoint center = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    CGFloat radius = fminf(bounds.size.width, bounds.size.height) * 0.5f - 6.0f;

    /* Outer drop shadow */
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 6), 10.0, [UIColor colorWithWhite:0.0 alpha:0.65].CGColor);
    CGContextSetFillColorWithColor(ctx, [UIColor blackColor].CGColor);
    CGContextFillEllipseInRect(ctx, CGRectMake(center.x - radius, center.y - radius, radius * 2.0, radius * 2.0));
    CGContextRestoreGState(ctx);

    /* Metallic Chrome Bezel Ring */
    CGRect circleRect = CGRectMake(center.x - radius, center.y - radius, radius * 2.0, radius * 2.0);
    CGContextSaveGState(ctx);
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:circleRect];
    [circlePath addClip];

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGFloat rimComp[8] = {
        0.85f, 0.90f, 0.98f, 1.0f, // Top chrome highlight
        0.20f, 0.28f, 0.40f, 1.0f  // Bottom metal shadow
    };
    CGFloat loc[2] = {0.0f, 1.0f};
    CGGradientRef rimGrad = CGGradientCreateWithColorComponents(cs, rimComp, loc, 2);
    CGContextDrawLinearGradient(ctx, rimGrad, CGPointMake(0, circleRect.origin.y), CGPointMake(0, circleRect.origin.y + circleRect.size.height), 0);
    CGGradientRelease(rimGrad);

    /* Inner Disc (Inset by 5px) */
    CGFloat innerRadius = radius - 5.0f;
    CGRect innerRect = CGRectMake(center.x - innerRadius, center.y - innerRadius, innerRadius * 2.0, innerRadius * 2.0);
    UIBezierPath *innerPath = [UIBezierPath bezierPathWithOvalInRect:innerRect];
    [innerPath addClip];

    /* Radial Blue Gradient */
    BOOL hl = self.isHighlighted;
    CGFloat blueComp[8] = {
        hl ? 0.12f : 0.22f, hl ? 0.60f : 0.72f, hl ? 0.95f : 1.00f, 1.0f, // Center bright electric blue
        hl ? 0.00f : 0.00f, hl ? 0.24f : 0.32f, hl ? 0.60f : 0.72f, 1.0f  // Edge deep royal blue
    };
    CGGradientRef blueGrad = CGGradientCreateWithColorComponents(cs, blueComp, loc, 2);
    CGContextDrawRadialGradient(ctx, blueGrad,
                               CGPointMake(center.x, center.y - innerRadius * 0.2f), 0.0f,
                               center, innerRadius,
                               kCGGradientDrawsAfterEndLocation);
    CGGradientRelease(blueGrad);

    /* Top Glass Reflection Arc */
    CGRect glossRect = CGRectMake(innerRect.origin.x, innerRect.origin.y, innerRect.size.width, innerRadius);
    CGFloat glossComp[8] = {
        1.0f, 1.0f, 1.0f, hl ? 0.25f : 0.45f,
        1.0f, 1.0f, 1.0f, 0.06f
    };
    CGGradientRef glossGrad = CGGradientCreateWithColorComponents(cs, glossComp, loc, 2);
    CGContextDrawLinearGradient(ctx, glossGrad, CGPointMake(0, glossRect.origin.y), CGPointMake(0, glossRect.origin.y + glossRect.size.height), 0);
    CGGradientRelease(glossGrad);
    CGColorSpaceRelease(cs);

    /* Shazam Logo In Center */
    CGFloat logoSize = innerRadius * 1.05f;
    CGRect logoRect = CGRectMake(center.x - logoSize * 0.5f,
                                 center.y - logoSize * 0.5f + (hl ? 1.0f : 0.0f),
                                 logoSize, logoSize);
    CGPathRef logoPath = SZCreateShazamPath(logoRect);

    // Drop shadow under logo
    CGContextSaveGState(ctx);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 2), 4.0, [UIColor colorWithRed:0.0 green:0.18 blue:0.42 alpha:0.75].CGColor);
    CGContextAddPath(ctx, logoPath);
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillPath(ctx);
    CGContextRestoreGState(ctx);

    CGPathRelease(logoPath);
    CGContextRestoreGState(ctx);
}

@end
