#ifndef SZFFT_H
#define SZFFT_H

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SZ_FFT_SIZE 2048
#define SZ_FFT_BINS 1025

typedef struct {
    float twiddle_cos[SZ_FFT_SIZE / 2];
    float twiddle_sin[SZ_FFT_SIZE / 2];
    unsigned short bitrev[SZ_FFT_SIZE];
} SZFFTContext;

void SZFFTInit(SZFFTContext *ctx);

/**
 * Computes forward real-to-complex FFT for 2048 points.
 * @param ctx Initialized FFT context.
 * @param realIn Pointer to 2048 float input samples.
 * @param realOut Pointer to array of at least 1025 floats for real output components.
 * @param imagOut Pointer to array of at least 1025 floats for imaginary output components.
 */
void SZFFTForward2048(const SZFFTContext *ctx, const float *realIn, float *realOut, float *imagOut);

#ifdef __cplusplus
}
#endif

#endif /* SZFFT_H */
