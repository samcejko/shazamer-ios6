#import <Foundation/Foundation.h>
#import "SZTrack.h"

@interface SZShazamClient : NSObject

+ (instancetype)sharedClient;

- (void)recognizeWithSignatureURI:(NSString *)signatureURI
                         sampleMs:(NSUInteger)sampleMs
                       completion:(void (^)(SZTrack *track, NSError *error))completion;

- (void)fetchCoverImageForTrack:(SZTrack *)track
                     completion:(void (^)(UIImage *image))completion;

- (void)cancel;

@end
