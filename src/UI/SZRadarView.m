#import "SZRadarView.h"
#import "SZTheme.h"
#import <QuartzCore/QuartzCore.h>

@interface SZRadarView () {
    NSTimer *_animTimer;
    float _phases[3];
}
@end

@implementation SZRadarView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        _phases[0] = 0.0f;
        _phases[1] = 0.33f;
        _phases[2] = 0.66f;
        _audioLevel = 0.0f;
        _pulseCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        _buttonRadius = 84.0f;
    }
    return self;
}

- (void)startPulsing
{
    if (_isPulsing) return;
    _isPulsing = YES;

    [_animTimer invalidate];
    _animTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 30.0
                                                  target:self
                                                selector:@selector(animTick)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stopPulsing
{
    if (!_isPulsing) return;
    _isPulsing = NO;
    [_animTimer invalidate];
    _animTimer = nil;
    _audioLevel = 0.0f;
    [self setNeedsDisplay];
}

- (void)setAudioLevel:(float)audioLevel
{
    _audioLevel = fmaxf(0.0f, fminf(1.0f, audioLevel));
}

- (void)setPulseCenter:(CGPoint)pulseCenter
{
    _pulseCenter = pulseCenter;
    [self setNeedsDisplay];
}

- (void)setButtonRadius:(CGFloat)buttonRadius
{
    _buttonRadius = buttonRadius;
    [self setNeedsDisplay];
}

- (void)animTick
{
    float speed = 0.015f + (_audioLevel * 0.025f);
    for (int i = 0; i < 3; i++) {
        _phases[i] += speed;
        if (_phases[i] >= 1.0f) {
            _phases[i] -= 1.0f;
        }
    }
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGPoint center = _pulseCenter;

    CGFloat baseRadius = _buttonRadius;
    CGFloat maxRadius = MAX(baseRadius, MIN(self.bounds.size.width, self.bounds.size.height) * 0.48f);

    if (_isPulsing) {
        for (int i = 0; i < 3; i++) {
            float phase = _phases[i];
            CGFloat radius = baseRadius + (CGFloat)phase * (maxRadius - baseRadius);
            CGFloat alpha = (1.0f - phase) * (0.35f + _audioLevel * 0.45f);

            CGRect ringRect = CGRectMake(center.x - radius, center.y - radius, radius * 2.0, radius * 2.0);
            CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:alpha].CGColor);
            CGContextSetLineWidth(ctx, 2.0 + _audioLevel * 3.0);
            CGContextStrokeEllipseInRect(ctx, ringRect);
        }
    } else {
        /* Soft resting glow circle */
        CGFloat radius = baseRadius + 8.0;
        CGRect ringRect = CGRectMake(center.x - radius, center.y - radius, radius * 2.0, radius * 2.0);
        CGContextSetStrokeColorWithColor(ctx, [UIColor colorWithRed:0.0 green:0.53 blue:1.0 alpha:0.18].CGColor);
        CGContextSetLineWidth(ctx, 1.5);
        CGContextStrokeEllipseInRect(ctx, ringRect);
    }
}

- (void)dealloc
{
    [_animTimer invalidate];
}

@end
