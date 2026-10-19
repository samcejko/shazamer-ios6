#import "SZSignatureGenerator.h"
#import "SZFFT.h"
#import "SZCommon.h"
#include <math.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

@implementation SZFrequencyPeak
@end

static const char kBase64Table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

static NSString *SZBase64Encode(const uint8_t *bytes, NSUInteger len)
{
    if (len == 0) return @"";
    NSUInteger outLen = ((len + 2) / 3) * 4;
    char *out = (char *)malloc(outLen + 1);
    if (!out) return @"";
    NSUInteger i = 0, j = 0;
    while (i + 2 < len) {
        uint32_t v = ((uint32_t)bytes[i] << 16) | ((uint32_t)bytes[i + 1] << 8) | (uint32_t)bytes[i + 2];
        out[j++] = kBase64Table[(v >> 18) & 63];
        out[j++] = kBase64Table[(v >> 12) & 63];
        out[j++] = kBase64Table[(v >> 6) & 63];
        out[j++] = kBase64Table[v & 63];
        i += 3;
    }
    if (i < len) {
        uint32_t v = (uint32_t)bytes[i] << 16;
        if (i + 1 < len) v |= (uint32_t)bytes[i + 1] << 8;
        out[j++] = kBase64Table[(v >> 18) & 63];
        out[j++] = kBase64Table[(v >> 12) & 63];
        out[j++] = (i + 1 < len) ? kBase64Table[(v >> 6) & 63] : '=';
        out[j++] = '=';
    }
    out[j] = 0;
    return [[NSString alloc] initWithBytesNoCopy:out length:j encoding:NSASCIIStringEncoding freeWhenDone:YES];
}

static uint32_t SZCRC32(const uint8_t *data, size_t length)
{
    uint32_t crc = 0xFFFFFFFF;
    for (size_t i = 0; i < length; i++) {
        crc ^= data[i];
        for (int j = 0; j < 8; j++) {
            crc = (crc >> 1) ^ (0xEDB88320 & -(crc & 1));
        }
    }
    return ~crc;
}

@implementation SZSignatureGenerator

+ (NSString *)signatureURIFromPCMData:(NSData *)pcmData
{
    if (!pcmData.length) return nil;
    const int16_t *samples = (const int16_t *)pcmData.bytes;
    NSUInteger count = pcmData.length / sizeof(int16_t);
    return [self signatureURIFromPCMBuffer:samples count:count];
}

+ (NSString *)signatureURIFromPCMBuffer:(const int16_t *)samples count:(NSUInteger)count
{
    NSData *binary = [self signatureBinaryFromPCMBuffer:samples count:count];
    if (!binary.length) return nil;
    NSString *b64 = SZBase64Encode((const uint8_t *)binary.bytes, binary.length);
    return [NSString stringWithFormat:@"data:audio/vnd.shazam.sig;base64,%@", b64];
}

+ (NSData *)signatureBinaryFromPCMBuffer:(const int16_t *)samples count:(NSUInteger)count
{
    if (!samples || count < 2048) {
        return nil;
    }

    SZFFTContext fftCtx;
    SZFFTInit(&fftCtx);

    float hanning[SZ_FFT_SIZE];
    for (int i = 0; i < SZ_FFT_SIZE; i++) {
        hanning[i] = 0.5f * (1.0f - (float)cos(2.0 * M_PI * (double)i / (double)SZ_FFT_SIZE));
    }

    int16_t ringBuffer[SZ_FFT_SIZE];
    memset(ringBuffer, 0, sizeof(ringBuffer));
    NSUInteger ringBufferIndex = 0;

    float reorderedSamples[SZ_FFT_SIZE];
    float fftReal[SZ_FFT_BINS];
    float fftImag[SZ_FFT_BINS];

    float fftOutputs[256][SZ_FFT_BINS];
    memset(fftOutputs, 0, sizeof(fftOutputs));
    uint8_t fftOutputsIndex = 0;

    float spreadOutputs[256][SZ_FFT_BINS];
    memset(spreadOutputs, 0, sizeof(spreadOutputs));
    uint8_t spreadOutputsIndex = 0;

    uint32_t numSpreadDone = 0;

    NSMutableArray *bandPeaks[4];
    for (int b = 0; b < 4; b++) {
        bandPeaks[b] = [NSMutableArray array];
    }

    static const int kNeighborOffsets[8] = {-10, -7, -4, -3, 1, 2, 5, 8};
    static const int kOtherOffsets[14] = {-53, -45, 165, 172, 179, 186, 193, 200, 214, 221, 228, 235, 242, 249};

    NSUInteger numChunks = count / 128;
    for (NSUInteger c = 0; c < numChunks; c++) {
        const int16_t *chunk = &samples[c * 128];

        /* Copy 128 samples into ring buffer */
        memcpy(&ringBuffer[ringBufferIndex], chunk, 128 * sizeof(int16_t));
        ringBufferIndex = (ringBufferIndex + 128) & 2047;

        /* Reorder and apply Hanning window */
        for (int i = 0; i < SZ_FFT_SIZE; i++) {
            int srcIdx = (i + ringBufferIndex) & 2047;
            reorderedSamples[i] = (float)ringBuffer[srcIdx] * hanning[i];
        }

        /* Forward FFT */
        SZFFTForward2048(&fftCtx, reorderedSamples, fftReal, fftImag);

        /* Real energy squared / 131072.0f */
        float *currFFT = fftOutputs[fftOutputsIndex];
        for (int i = 0; i < SZ_FFT_BINS; i++) {
            float energy = (fftReal[i] * fftReal[i] + fftImag[i] * fftImag[i]) / 131072.0f;
            if (energy < 1e-10f) energy = 1e-10f;
            currFFT[i] = energy;
        }
        fftOutputsIndex = (fftOutputsIndex + 1) & 0xFF;

        /* Peak spreading - frequency domain */
        float *spreadCurr = spreadOutputs[spreadOutputsIndex];
        memcpy(spreadCurr, currFFT, SZ_FFT_BINS * sizeof(float));
        for (int pos = 0; pos <= 1022; pos++) {
            float maxVal = spreadCurr[pos];
            if (spreadCurr[pos + 1] > maxVal) maxVal = spreadCurr[pos + 1];
            if (spreadCurr[pos + 2] > maxVal) maxVal = spreadCurr[pos + 2];
            spreadCurr[pos] = maxVal;
        }

        /* Peak spreading - time domain */
        static const int formerOffsets[3] = {1, 3, 6};
        for (int fo = 0; fo < 3; fo++) {
            uint8_t formerIdx = (spreadOutputsIndex - formerOffsets[fo]) & 0xFF;
            float *former = spreadOutputs[formerIdx];
            for (int pos = 0; pos < SZ_FFT_BINS; pos++) {
                if (spreadCurr[pos] > former[pos]) {
                    former[pos] = spreadCurr[pos];
                }
            }
        }

        spreadOutputsIndex = (spreadOutputsIndex + 1) & 0xFF;
        numSpreadDone++;

        /* Peak recognition */
        if (numSpreadDone >= 46) {
            uint8_t idxMinus46 = (fftOutputsIndex - 46) & 0xFF;
            uint8_t idxMinus49 = (spreadOutputsIndex - 49) & 0xFF;
            const float *fftMinus46 = fftOutputs[idxMinus46];
            const float *spreadMinus49 = spreadOutputs[idxMinus49];

            for (int bin = 10; bin <= 1014; bin++) {
                float val = fftMinus46[bin];
                if (val < (1.0f / 64.0f) || val < spreadMinus49[bin - 1]) {
                    continue;
                }

                float maxNeighbor = 0.0f;
                for (int no = 0; no < 8; no++) {
                    int neighborBin = bin + kNeighborOffsets[no];
                    if (neighborBin >= 0 && neighborBin < SZ_FFT_BINS) {
                        if (spreadMinus49[neighborBin] > maxNeighbor) {
                            maxNeighbor = spreadMinus49[neighborBin];
                        }
                    }
                }

                if (val <= maxNeighbor) continue;

                float maxOther = maxNeighbor;
                for (int oo = 0; oo < 14; oo++) {
                    uint8_t otherIdx = ((int)spreadOutputsIndex + kOtherOffsets[oo]) & 0xFF;
                    float otherVal = spreadOutputs[otherIdx][bin - 1];
                    if (otherVal > maxOther) {
                        maxOther = otherVal;
                    }
                }

                if (val <= maxOther) continue;

                /* Peak confirmed! */
                uint32_t passNumber = numSpreadDone - 46;

                float magCenter = logf(fmaxf(val, 1.0f / 64.0f)) * 1477.3f + 6144.0f;
                float magBefore = logf(fmaxf(fftMinus46[bin - 1], 1.0f / 64.0f)) * 1477.3f + 6144.0f;
                float magAfter  = logf(fmaxf(fftMinus46[bin + 1], 1.0f / 64.0f)) * 1477.3f + 6144.0f;

                float var1 = magCenter * 2.0f - magBefore - magAfter;
                float var2 = (magAfter - magBefore) * 32.0f / (var1 > 0.0001f ? var1 : 1.0f);

                uint16_t correctedBin = (uint16_t)((bin * 64) + (int)var2);
                float freqHz = (float)correctedBin * (16000.0f / 2.0f / 1024.0f / 64.0f);

                int band = -1;
                if (freqHz >= 250.0f && freqHz < 520.0f) band = 0;
                else if (freqHz >= 520.0f && freqHz < 1450.0f) band = 1;
                else if (freqHz >= 1450.0f && freqHz < 3500.0f) band = 2;
                else if (freqHz >= 3500.0f && freqHz <= 5500.0f) band = 3;

                if (band >= 0) {
                    SZFrequencyPeak *peak = [[SZFrequencyPeak alloc] init];
                    peak.fftPassNumber = passNumber;
                    peak.peakMagnitude = (uint16_t)magCenter;
                    peak.correctedPeakFrequencyBin = correctedBin;
                    [bandPeaks[band] addObject:peak];
                }
            }
        }
    }

    /* Encode to Shazam binary payload */
    NSMutableData *data = [NSMutableData data];

    /* 48-byte header: write placeholders */
    uint32_t magic1 = 0xcafe2580;
    uint32_t crc32Placeholder = 0;
    uint32_t sizeMinusHeader = 0;
    uint32_t magic2 = 0x94119c00;
    uint32_t void1[3] = {0, 0, 0};
    uint32_t shiftedSampleRateId = 3 << 27; /* 16000 Hz */
    uint32_t void2[2] = {0, 0};
    uint32_t numSamplesPlus = (uint32_t)(count + (16000.0f * 0.24f));
    uint32_t fixedValue = (15 << 19) + 0x40000;

    [data appendBytes:&magic1 length:4];
    [data appendBytes:&crc32Placeholder length:4];
    [data appendBytes:&sizeMinusHeader length:4];
    [data appendBytes:&magic2 length:4];
    [data appendBytes:void1 length:12];
    [data appendBytes:&shiftedSampleRateId length:4];
    [data appendBytes:void2 length:8];
    [data appendBytes:&numSamplesPlus length:4];
    [data appendBytes:&fixedValue length:4];

    /* Container header */
    uint32_t containerTag = 0x40000000;
    uint32_t containerSize = 0;
    [data appendBytes:&containerTag length:4];
    [data appendBytes:&containerSize length:4];

    /* Frequency bands */
    for (int b = 0; b < 4; b++) {
        NSArray *peaks = bandPeaks[b];
        if (!peaks.count) continue;

        NSMutableData *peaksData = [NSMutableData data];
        uint32_t lastPass = 0;

        for (SZFrequencyPeak *peak in peaks) {
            uint32_t pass = peak.fftPassNumber;
            if (pass < lastPass) pass = lastPass;

            if (pass - lastPass >= 255) {
                uint8_t marker = 0xFF;
                [peaksData appendBytes:&marker length:1];
                uint32_t fullPass = pass;
                [peaksData appendBytes:&fullPass length:4];
                lastPass = pass;
            }

            uint8_t delta = (uint8_t)(pass - lastPass);
            [peaksData appendBytes:&delta length:1];

            uint16_t mag = peak.peakMagnitude;
            uint16_t bin = peak.correctedPeakFrequencyBin;
            [peaksData appendBytes:&mag length:2];
            [peaksData appendBytes:&bin length:2];

            lastPass = pass;
        }

        uint32_t bandTag = 0x60030040 + b;
        uint32_t bandLen = (uint32_t)peaksData.length;
        [data appendBytes:&bandTag length:4];
        [data appendBytes:&bandLen length:4];
        [data appendData:peaksData];

        /* Pad to 4-byte alignment */
        NSUInteger padding = (4 - (bandLen % 4)) % 4;
        for (NSUInteger p = 0; p < padding; p++) {
            uint8_t zero = 0;
            [data appendBytes:&zero length:1];
        }
    }

    uint32_t totalLen = (uint32_t)data.length;
    uint32_t payloadSize = totalLen - 48;

    /* Write size_minus_header at offset 8 and offset 52 */
    [data replaceBytesInRange:NSMakeRange(8, 4) withBytes:&payloadSize];
    [data replaceBytesInRange:NSMakeRange(52, 4) withBytes:&payloadSize];

    /* Compute CRC32 from byte 8 to end, and write at offset 4 */
    const uint8_t *allBytes = (const uint8_t *)data.bytes;
    uint32_t computedCRC = SZCRC32(&allBytes[8], totalLen - 8);
    [data replaceBytesInRange:NSMakeRange(4, 4) withBytes:&computedCRC];

    return data;
}

@end
