#include "asm.S"

@ ff_neon_yuv420_bgr24(uint8_t *Y, uint8_t *U, uint8_t *V, uint8_t *out,
@                      uint64_t *data)  // data includes offsets and coefficients

function ff_neon_yuv420_bgr24, export=1
    @ load data into registers
    vld2.32 {q1},    [r0, :128] @ Y, split into registers for even/odd pixels
    vld1.32 {d6},    [r1, :64]  @ U
    vld1.32 {d8},    [r2, :64]  @ V

    ldr r0, [sp]            @ extra parameter
    vld1.16 {q0},    [r0]   @ loads 8x16-bit scalars: oy, oc, cy, crv, cbu, cgu, cgv, pad

    @ process each YUV pixel by the following:
    @ X' = X*8 - Xoffset

    @ q1, q2 == y
    vdup.16 q5, d0[0]  @ y offset

    vshll.u8 q2, d3, #3
    vshll.u8 q1, d2, #3
    vsub.i16 q1, q1, q5
    vsub.i16 q2, q2, q5

    @ calculate Y' * Ycoeff

    vmull.s16 q6, d3, d0[2]
    vmull.s16 q5, d2, d0[2]
    vmull.s16 q8, d5, d0[2]
    vmull.s16 q7, d4, d0[2]
    @ 32 - (11 + 11)
    vrshrn.s32 d2, q5, #10
    vrshrn.s32 d3, q6, #10
    vrshrn.s32 d4, q7, #10
    vrshrn.s32 d5, q8, #10

    @ q6 = u, q7 = v
    vdup.16 q6, d0[1] @ load with chroma offseet

    @ calculate U' = U * 8 - chroma_offset, same for V
    vshll.u8 q3, d6, #3
    vshll.u8 q4, d8, #3
    vsub.s16 q3, q3, q6
    vsub.s16 q4, q4, q6

    @ Calculate V' * Vred
    vmull.s16 q9, d8, d0[3]
    vmull.s16 q10, d9, d0[3]
    vshrn.s32 d14, q9, #10
    vshrn.s32 d15, q10, #10

    @ R = Y' * Ycoef + V' * Vred
    vqadd.s16 q10, q1, q7
    vqadd.s16 q11, q2, q7
    vrshrn.s16 d20, q10, #8
    vrshrn.s16 d21, q11, #8
    vzip.u8 d20, d21

    @ B = Y ' * Ycoef + U' * Ublue
    vmull.s16 q8, d6, d1[0]
    vmull.s16 q9, d7, d1[0]
    vshrn.s32 d14, q8, #9
    vshrn.s32 d15, q9, #9

    vqadd.s16 q11, q1, q7
    vqadd.s16 q12, q2, q7
    vshrn.s16 d24, q11, #8
    vshrn.s16 d25, q12, #8
    vzip.u8 d24, d25

    @ G = Y' * Ycoef + U' * Ugreen + V' + Vgreen
    vmull.s16 q7, d6, d1[1] @ U' + Ugreen
    vmull.s16 q8, d7, d1[1]
    vshrn.s32 d14, q7, #10
    vshrn.s32 d15, q8, #10

    vmull.s16 q8, d8, d1[2] @ V' + Vgreen
    vmull.s16 q9, d9, d1[2]
    vshrn.s32 d16, q8, #10
    vshrn.s32 d17, q9, #10

    vqadd.s16 q7, q7, q8  @ U' * Ugreen + V' * Vgreen
    vqadd.s16 q11, q1, q7 @ add chroma to Y1
    vqadd.s16 q13, q2, q7 @ add chroma to Y2
    vshrn.s16 d22, q11, #8
    vshrn.s16 d23, q13, #8

    vst3.8 {d20, d22, d24}, [r3, :64]!
    vst3.8 {d21, d23, d25}, [r3, :64]

    bx lr
endfunc
