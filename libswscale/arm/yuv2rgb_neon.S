#include "asm.S"

@ ff_neon_yuv420_bgr24(uint8_t *Y, uint8_t *U, uint8_t *V, uint8_t *out,
@                      uint64_t *data)  // data includes offsets and coefficients

function ff_neon_yuv420_bgr24, export=1
    @ load data into registers
    vld2.8 {q1},    [r0, :128] @ Y, split into registers for even/odd pixels
    ldr r0, [sp]            @ extra parameter
    vld1.16 {q0},    [r0]   @ loads 8x16-bit scalars: oy, oc, cy, crv, cbu, cgu, cgv, pad

    @ process each YUV pixel by the following:
    @ X' = X*8 - Xoffset

    vshll.u8 q3, d3, #3   @ Y * 8
    vshll.u8 q1, d2, #3
    vdup.u16 q9, d0[0]
    vqsub.u16 q1, q1, q9  @ Y' = Y * 8 - Yoffset
    vqsub.u16 q3, q3, q9

    vqdmulh.s16 q1, q1, d0[2]    @ Y' * Ycoeff
    vqdmulh.s16 q3, q3, d0[2]

    vld1.32 {d10},    [r1, :64]  @ U
    vld1.32 {d12},    [r2, :64]  @ V

    @ load chroma and scale
    vshll.u8 q5, d10, #3  @ U * 8
    vshll.u8 q6, d12, #3  @ V * 8
    vdup.u16 q7, d0[1]
    vqsub.s16 q5, q5, q7  @ U' = U * 8 - Coffset
    vqsub.s16 q6, q6, q7  @ V' = V * 8 - Coffset

    vqdmulh.s16 q7, q6, d0[3]  @ V' * Vred

    vqdmulh.s16 q8, q5, d1[0]  @ U' * Ugreen

    vqdmulh.s16 q9, q6, d1[1]  @ V' * Vgreen
    vqadd.s16 q8, q8, q9       @ (U' * Ugreen) + (V' * Vred)

    vqdmulh.s16 q9, q5, d1[2]  @ U' * UBlue

    @ R = Y' * Ycoeff + V' * Vred
    vqadd.s16 q10,  q1, q7
    vqadd.s16 q11,  q3, q7
    vqshrun.s16 d26, q10, #1  @ compensate for doubling multiply
    vqshrun.s16 d27, q11, #1
    vzip.u8 d26, d27

    @ G = Y' * Ycoeff + U' * Ugreen + V' * Vgreen
    vqadd.s16 q10, q1, q8
    vqadd.s16 q11, q3, q8
    vqshrun.s16 d28, q10, #1
    vqshrun.s16 d29, q11, #1
    vzip.u8 d28, d29

    @ B = Y' * Ycoeff + U' * Ublue
    vqadd.s16 q10,  q1, q9
    vqadd.s16 q11, q3, q9
    vqshrun.s16 d30, q10, #1
    vqshrun.s16 d31, q11, #1
    vzip.u8 d30, d31

    vst3.8 {d26, d28, d30}, [r3, :64]!
    vst3.8 {d27, d29, d31}, [r3, :64]

    bx lr
endfunc
