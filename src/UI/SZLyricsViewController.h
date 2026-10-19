#import <UIKit/UIKit.h>
#import "SZTrack.h"

@interface SZLyricsViewController : UIViewController

@property (nonatomic, strong) SZTrack *track;

- (instancetype)initWithTrack:(SZTrack *)track;

@end
