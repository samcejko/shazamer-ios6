#import <Foundation/Foundation.h>
#import "SZSignatureGenerator.h"
#include <pthread.h>
#include <math.h>
#include <assert.h>

static uint32_t word(NSData *d, NSUInteger off) {
    uint32_t v; memcpy(&v, (const char *)d.bytes + off, 4); return v;
}
static void validate(NSData *d) {
    assert(d.length >= 56);
    assert(word(d, 0) == 0xcafe2580);
    assert(word(d, 8) == d.length - 48);
    assert(word(d, 52) == d.length - 48);
    uint32_t crc = 0xffffffff;
    const uint8_t *b = d.bytes;
    for (NSUInteger i = 8; i < d.length; i++) {
        crc ^= b[i];
        for (int j=0;j<8;j++) crc=(crc>>1)^(0xedb88320 & -(crc&1));
    }
    assert(~crc == word(d, 4));
}
static void *exercise(void *unused) {
    @autoreleasepool {
        assert(![SZSignatureGenerator signatureBinaryFromPCMBuffer:NULL count:0]);
        for (int seconds=4; seconds<=12; seconds+=4) {
            @autoreleasepool {
                NSMutableData *pcm=[NSMutableData dataWithLength:seconds*16000*2];
                int16_t *p=pcm.mutableBytes;
                NSData *silence=[SZSignatureGenerator signatureBinaryFromPCMBuffer:p count:pcm.length/2];
                validate(silence); assert(silence.length==56);
                uint32_t seed=17;
                for (NSUInteger i=0;i<pcm.length/2;i++) {
                    seed=seed*1664525+1013904223;
                    p[i]=(int16_t)(seed>>16);
                }
                validate([SZSignatureGenerator signatureBinaryFromPCMBuffer:p count:pcm.length/2]);
            }
        }
    }
    return NULL;
}
int main(int argc, const char **argv) {
    @autoreleasepool {
        pthread_attr_t attr; pthread_attr_init(&attr);
        assert(!pthread_attr_setstacksize(&attr,512*1024));
        pthread_t thread; assert(!pthread_create(&thread,&attr,exercise,NULL));
        pthread_attr_destroy(&attr); pthread_join(thread,NULL);
        fprintf(stderr,"Fingerprint regression PASS on 512 KiB worker stack (4/8/12 s, silence/noise, CRC)\n");
        if (argc==3) {
            NSData *pcm=[NSData dataWithContentsOfFile:@(argv[1])]; assert(pcm.length>=4096);
            NSData *binary=[SZSignatureGenerator signatureBinaryFromPCMBuffer:pcm.bytes count:pcm.length/2];
            validate(binary); assert([binary writeToFile:@(argv[2]) atomically:YES]);
        }
    }
    return 0;
}
