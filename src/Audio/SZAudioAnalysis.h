#include <stddef.h>
#include <stdint.h>

// Require at least 100 ms above roughly -55 dBFS; reject silence and isolated clicks.
static inline int SZPCMHasAudibleSignal(const int16_t *samples, size_t count)
{
    if (!samples || count < 320) return 0;
    unsigned audibleWindows = 0;
    const double threshold = 32768.0 * 0.0018;
    for (size_t offset = 0; offset + 320 <= count; offset += 320) {
        double sum = 0, squareSum = 0;
        for (size_t i = 0; i < 320; i++) {
            double value = samples[offset + i];
            sum += value;
            squareSum += value * value;
        }
        // Remove DC bias: a stuck microphone signal is not audible music.
        double mean = sum / 320.0;
        if (squareSum / 320.0 - mean * mean >= threshold * threshold && ++audibleWindows >= 5) return 1;
    }
    return 0;
}
