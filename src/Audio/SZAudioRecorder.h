#import <Foundation/Foundation.h>

typedef void (^SZAudioLevelBlock)(float level); // 0.0 to 1.0
typedef void (^SZAudioRecordCompletionBlock)(NSData *pcmData, NSError *error);

@interface SZAudioRecorder : NSObject

@property (nonatomic, readonly) BOOL isRecording;
@property (nonatomic) NSTimeInterval targetDuration; // default 6.0 seconds

@property (nonatomic, copy) SZAudioLevelBlock onLevelUpdate;
@property (nonatomic, copy) SZAudioRecordCompletionBlock onComplete;

+ (instancetype)sharedRecorder;

- (BOOL)startRecordingWithDuration:(NSTimeInterval)duration
                           onLevel:(SZAudioLevelBlock)levelBlock
                        completion:(SZAudioRecordCompletionBlock)completionBlock;

- (void)stopRecording;
- (void)cancelRecording;

@end
