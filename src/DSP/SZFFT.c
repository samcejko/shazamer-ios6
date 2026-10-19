#include "SZFFT.h"
#include <math.h>
#include <string.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

void SZFFTInit(SZFFTContext *ctx)
{
    if (!ctx) return;

    /* Precompute twiddle factors for e^(-2*pi*i * k / 2048) */
    for (int k = 0; k < SZ_FFT_SIZE / 2; k++) {
        double angle = -2.0 * M_PI * (double)k / (double)SZ_FFT_SIZE;
        ctx->twiddle_cos[k] = (float)cos(angle);
        ctx->twiddle_sin[k] = (float)sin(angle);
    }

    /* Precompute bit reversal lookup table for 11 bits (2048) */
    for (int i = 0; i < SZ_FFT_SIZE; i++) {
        unsigned int rev = 0;
        unsigned int temp = i;
        for (int b = 0; b < 11; b++) {
            rev = (rev << 1) | (temp & 1);
            temp >>= 1;
        }
        ctx->bitrev[i] = (unsigned short)rev;
    }
}

void SZFFTForward2048(const SZFFTContext *ctx, const float *realIn, float *realOut, float *imagOut)
{
    float r[SZ_FFT_SIZE];
    float im[SZ_FFT_SIZE];

    /* Bit-reversal copy */
    for (int i = 0; i < SZ_FFT_SIZE; i++) {
        unsigned short target = ctx->bitrev[i];
        r[target] = realIn[i];
        im[target] = 0.0f;
    }

    /* Cooley-Tukey Radix-2 DIT FFT */
    for (int s = 1; s <= 11; s++) {
        int m = 1 << s;
        int m2 = m >> 1;
        int step = SZ_FFT_SIZE / m;

        for (int j = 0; j < m2; j++) {
            int tw_idx = j * step;
            /* e^(-i theta) = cos(theta) + i*sin(theta) where sin is already negative */
            float c = ctx->twiddle_cos[tw_idx];
            float s_val = ctx->twiddle_sin[tw_idx];

            for (int k = j; k < SZ_FFT_SIZE; k += m) {
                int pair = k + m2;
                /* (c + i*s_val) * (r[pair] + i*im[pair]) */
                float tr = c * r[pair] - s_val * im[pair];
                float ti = c * im[pair] + s_val * r[pair];

                float ur = r[k];
                float ui = im[k];

                r[k] = ur + tr;
                im[k] = ui + ti;
                r[pair] = ur - tr;
                im[pair] = ui - ti;
            }
        }
    }

    /* Copy first 1025 bins (0 to Nyquist) */
    if (realOut) {
        memcpy(realOut, r, SZ_FFT_BINS * sizeof(float));
    }
    if (imagOut) {
        memcpy(imagOut, im, SZ_FFT_BINS * sizeof(float));
    }
}
