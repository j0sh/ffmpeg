#include "asm.S"

@ ff_neon_yuv420_bgr24(uint8_t *Y, uint8_t *U, uint8_t *V, uint8_t *out,
@                      uint64_t *data)  // data includes offsets and coefficients

function ff_neon_yuv420_bgr24, export=1
    @ load data into registers
    vld2.32 {q0},    [r0, :128] @ Y, split into registers for even/odd pixels
    vld1.32 {d2},    [r1, :64]  @ U
    vld1.32 {d4},    [r2, :64]  @ V

    ldr r0, [sp]             @ extra parameter
    vld1.16 {q3},    [r0]    @ loads 7x16-bit scalars: oy, oc, crv, cbu, cgu, cgv

    @ process each YUV pixel by the following:
    @ X' = X - Xoffset

    @ Widen to 16bit
    vmovl.u8 q10, d0 @ Y
    vmovl.u8 q11, d1
    vmovl.u8 q12, d2 @ U
    vmovl.u8 q13, d4 @ V

    @ subtract by offsets
    vdup.s16 q14, d6[0]    @ luma offset
    vdup.s16 q15, d6[1]    @ chroma offset
    vsub.s16 q10, q10, q14 @ Y'
    vsub.s16 q11, q11, q14
    vsub.s16 q12, q12, q15 @ U'
    vsub.s16 q13, q13, q15 @ V'

    @ calculate R = Y' * Ycoef + V' * Vred, place in q7

    @ calculate and store Y' * Ycoef
    vqdmulh.s16 q10, q10, d6[2] @ first half of Y'
    vqdmulh.s16 q11, q11, d6[2] @ second half of Y'
    vshr.s16 q10, q10, #1    @ get rid of the doubling from vqmuldh
    vshr.s16 q11, q11, #1

    vqdmulh.s16 q14, q13, d6[3]  @ V' * Vred
    vshr.s16 q14, q14, #1

    vraddhn.s16 d14, q10, q14
    vraddhn.s16 d15, q11, q14
    vzip.u8 d14, d15         @ re-interleave even/odd Y values

    @ calculate B = Y' * Ycoef + U' * Ublue, place in q9

    vqdmulh.s16 q14, q12, d7[0] @ U' * Ublue
    vshr.s16    q14, q14, #1

    vraddhn.i16 d18, q10, q14
    vraddhn.i16 d19, q11, q14
    vzip.u8     d18, d19

    @ calculate G = Y' * Ycoef + V' * Vgreen + U' * Ugreen, place in q8

    vqdmulh.s16 q14, q13, d7[1] @ U' * Ugreen
    vshr.s16 q14, q14, #1

    vqdmulh.s16 q15, q13, d7[2]  @ V' * Vgreen
    vshr.s16 q15, q15, #1

    vadd.i16 q14, q14, q15
    vraddhn.i16 d16, q10, q14
    vraddhn.i16 d17, q11, q14
    vzip.u8 d16, d17

    vst3.8 {d14, d16, d18}, [r3]!
    vst3.8 {d15, d17, d19}, [r3]

    bx lr
endfunc
