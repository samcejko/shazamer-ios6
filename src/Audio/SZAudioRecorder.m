#import "SZAudioRecorder.h"
#import "SZCommon.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define SZ_SAMPLE_RATE 16000.0
#define SZ_NUM_BUFFERS 3
#define SZ_BUFFER_DURATION 0.15 // seconds per buffer

@interface SZAudioRecorder () {
    AudioQueueRef _audioQueue;
    AudioQueueBufferRef _buffers[SZ_NUM_BUFFERS];
    AudioStreamBasicDescription _audioFormat;
    NSMutableData *_accumulatedPCM;
    NSUInteger _targetSampleCount;
    BOOL _isRecording;
    BOOL _waitingPermission;
    NSUInteger _generation;
}
- (void)processAudioBuffer:(AudioQueueBufferRef)buffer;
- (void)processPCMData:(NSData *)data;
- (BOOL)beginRecording;
@end

static void SZAudioQueueInputCallback(void *inUserData,
                                      AudioQueueRef inAQ,
                                      AudioQueueBufferRef inBuffer,
                                      const AudioTimeStamp *inStartTime,
                                      UInt32 inNumberPacketDescriptions,
                                      const AudioStreamPacketDescription *inPacketDescs)
{
    SZAudioRecorder *self = (__bridge SZAudioRecorder *)inUserData;
    if (!self || !self.isRecording) return;

    if (inBuffer->mAudioDataByteSize > 0) {
        [self processAudioBuffer:inBuffer];
    }

    if (self.isRecording) {
        AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, NULL);
    }
}

@implementation SZAudioRecorder

+ (instancetype)sharedRecorder
{
    static SZAudioRecorder *s_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_instance = [[SZAudioRecorder alloc] init];
    });
    return s_instance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _targetDuration = 6.0;
        _accumulatedPCM = [NSMutableData data];

        memset(&_audioFormat, 0, sizeof(_audioFormat));
        _audioFormat.mSampleRate = SZ_SAMPLE_RATE;
        _audioFormat.mFormatID = kAudioFormatLinearPCM;
        _audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        _audioFormat.mFramesPerPacket = 1;
        _audioFormat.mChannelsPerFrame = 1;
        _audioFormat.mBitsPerChannel = 16;
        _audioFormat.mBytesPerPacket = 2;
        _audioFormat.mBytesPerFrame = 2;
    }
    return self;
}

- (BOOL)isRecording
{
    return _isRecording || _waitingPermission;
}

- (BOOL)startRecordingWithDuration:(NSTimeInterval)duration
                           onLevel:(SZAudioLevelBlock)levelBlock
                        completion:(SZAudioRecordCompletionBlock)completionBlock
{
    [self cancelRecording];

    self.onLevelUpdate = levelBlock;
    self.onComplete = completionBlock;
    _targetDuration = (duration > 2.0) ? duration : 6.0;
    _targetSampleCount = (NSUInteger)(_targetDuration * SZ_SAMPLE_RATE);

    [_accumulatedPCM setLength:0];

    AVAudioSession *session = [AVAudioSession sharedInstance];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
    if ([session respondsToSelector:@selector(requestRecordPermission:)]) {
        _waitingPermission = YES;
        NSUInteger generation = _generation;
        [session requestRecordPermission:^(BOOL granted) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (generation != self->_generation || !self->_waitingPermission) return;
                self->_waitingPermission = NO;
                if (granted) [self beginRecording];
                else if (self.onComplete) self.onComplete(nil, SZMakeError(SZErrorMicDenied, L(@"MIC_PERMISSION_DENIED")));
            });
        }];
        return YES;
    }
#pragma clang diagnostic pop
    return [self beginRecording];
}

- (BOOL)beginRecording
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *sessionError = nil;
    if (![session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError] ||
        ![session setActive:YES error:&sessionError]) {
        if (self.onComplete) self.onComplete(nil, sessionError);
        return NO;
    }

    OSStatus status = AudioQueueNewInput(&_audioFormat,
                                        SZAudioQueueInputCallback,
                                        (__bridge void *)self,
                                        NULL,
                                        kCFRunLoopCommonModes,
                                        0,
                                        &_audioQueue);
    if (status != noErr) {
        SZLog(@"AudioQueueNewInput failed with status %d", (int)status);
        if (self.onComplete) {
            self.onComplete(nil, SZMakeError(SZErrorNetwork, L(@"RECORDING_FAILED")));
        }
        return NO;
    }

    UInt32 bufferByteSize = (UInt32)(_audioFormat.mSampleRate * SZ_BUFFER_DURATION * _audioFormat.mBytesPerFrame);
    for (int i = 0; i < SZ_NUM_BUFFERS; i++) {
        status = AudioQueueAllocateBuffer(_audioQueue, bufferByteSize, &_buffers[i]);
        if (status == noErr) status = AudioQueueEnqueueBuffer(_audioQueue, _buffers[i], 0, NULL);
        if (status != noErr) {
            AudioQueueDispose(_audioQueue, YES);
            _audioQueue = NULL;
            if (self.onComplete) self.onComplete(nil, SZMakeError(SZErrorNetwork, L(@"RECORDING_FAILED")));
            return NO;
        }
    }

    _isRecording = YES;
    status = AudioQueueStart(_audioQueue, NULL);
    if (status != noErr) {
        _isRecording = NO;
        SZLog(@"AudioQueueStart failed with status %d", (int)status);
        AudioQueueDispose(_audioQueue, YES);
        _audioQueue = NULL;
        if (self.onComplete) {
            self.onComplete(nil, SZMakeError(SZErrorNetwork, L(@"RECORDING_FAILED")));
        }
        return NO;
    }

    _isRecording = YES;
    SZLog(@"Started recording for %.1f seconds (%lu samples)", _targetDuration, (unsigned long)_targetSampleCount);
    return YES;
}

- (void)processAudioBuffer:(AudioQueueBufferRef)buffer
{
    // AudioQueueStop/Dispose must run after this callback has returned.
    NSData *data = [NSData dataWithBytes:buffer->mAudioData length:buffer->mAudioDataByteSize];
    NSUInteger generation = _generation;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (generation == self->_generation) [self processPCMData:data];
    });
}

- (void)processPCMData:(NSData *)data
{
    @synchronized(self) {
        if (!_isRecording) return;

        [_accumulatedPCM appendData:data];

        /* Calculate RMS Level for UI meter */
        const int16_t *samples = (const int16_t *)data.bytes;
        NSUInteger sampleCount = data.length / sizeof(int16_t);
        double sum = 0.0;
        for (NSUInteger i = 0; i < sampleCount; i++) {
            double normalized = (double)samples[i] / 32768.0;
            sum += normalized * normalized;
        }
        double rms = sqrt(sum / (sampleCount > 0 ? sampleCount : 1));
        float level = (float)fmin(1.0, rms * 6.0); // Scaled for lively UI reactivity

        if (self.onLevelUpdate) {
            SZMain(^{
                if (self.isRecording && self.onLevelUpdate) {
                    self.onLevelUpdate(level);
                }
            });
        }

        NSUInteger currentSamples = _accumulatedPCM.length / sizeof(int16_t);
        if (currentSamples >= _targetSampleCount) {
            [self finishRecording];
        }
    }
}

- (void)finishRecording
{
    if (!_isRecording) return;
    _isRecording = NO;

    if (_audioQueue) {
        AudioQueueStop(_audioQueue, YES);
        AudioQueueDispose(_audioQueue, YES);
        _audioQueue = NULL;
    }

    NSData *finalData = [_accumulatedPCM copy];
    SZLog(@"Recording finished. Captured %lu bytes (%lu samples)",
          (unsigned long)finalData.length, (unsigned long)(finalData.length / sizeof(int16_t)));

    SZMain(^{
        if (self.onComplete) {
            self.onComplete(finalData, nil);
        }
    });
}

- (void)stopRecording
{
    if (_waitingPermission) { [self cancelRecording]; return; }
    [self finishRecording];
}

- (void)cancelRecording
{
    _generation++;
    _waitingPermission = NO;
    if (!_isRecording) return;
    _isRecording = NO;

    if (_audioQueue) {
        AudioQueueStop(_audioQueue, YES);
        AudioQueueDispose(_audioQueue, YES);
        _audioQueue = NULL;
    }

    [_accumulatedPCM setLength:0];
    SZLog(@"Recording cancelled");
}

- (void)dealloc
{
    [self cancelRecording];
}

@end
