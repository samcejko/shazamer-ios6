#import <UIKit/UIKit.h>

@interface SZRadarView : UIView

@property (nonatomic) BOOL isPulsing;
@property (nonatomic) float audioLevel; // 0.0 to 1.0

- (void)startPulsing;
- (void)stopPulsing;

@end
