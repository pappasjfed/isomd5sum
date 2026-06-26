/*
 * SHA-256 hash implementation
 * Adapted from public domain implementation
 */

#ifndef SHA256_H
#define SHA256_H

#ifdef _WIN32
#include <stdint.h>
typedef uint32_t uint32;
typedef uint8_t uint8;
#else
#include <sys/types.h>
typedef u_int32_t uint32;
typedef u_int8_t uint8;
#endif

#include <stddef.h>

struct SHA256Context {
    uint32 state[8];
    uint32 count[2];
    uint8 buffer[64];
};

void SHA256_Init(struct SHA256Context *);
void SHA256_Update(struct SHA256Context *, const uint8 *, size_t);
void SHA256_Final(uint8 digest[32], struct SHA256Context *);

typedef struct SHA256Context SHA256_CTX;

#endif /* SHA256_H */
