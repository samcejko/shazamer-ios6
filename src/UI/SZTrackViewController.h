#import <UIKit/UIKit.h>
#import "SZTrack.h"

@interface SZTrackViewController : UIViewController

@property (nonatomic, strong) SZTrack *track;

- (instancetype)initWithTrack:(SZTrack *)track;

@end
