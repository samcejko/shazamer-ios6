#import <UIKit/UIKit.h>

@interface SZTagButton : UIButton

@property (nonatomic) BOOL isListening;

- (void)startListeningPulse;
- (void)stopListeningPulse;

@end
