#import <Foundation/Foundation.h>

@interface SZFrequencyPeak : NSObject
@property (nonatomic) uint32_t fftPassNumber;
@property (nonatomic) uint16_t peakMagnitude;
@property (nonatomic) uint16_t correctedPeakFrequencyBin;
@end

@interface SZSignatureGenerator : NSObject

/**
 * Generates a Shazam-compatible Data URI signature (data:audio/vnd.shazam.sig;base64,...)
 * from 16,000 Hz 16-bit mono PCM samples.
 */
+ (NSString *)signatureURIFromPCMData:(NSData *)pcmData;
+ (NSString *)signatureURIFromPCMBuffer:(const int16_t *)samples count:(NSUInteger)count;

/**
 * Returns raw binary signature bytes.
 */
+ (NSData *)signatureBinaryFromPCMBuffer:(const int16_t *)samples count:(NSUInteger)count;

@end
