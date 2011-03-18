#include "asm.S"

@ ff_neon_yuv420_bgr24(uint8_t *Y, uint8_t *U, uint8_t *V, uint8_t *out,
@                      uint64_t *data)  // data includes offsets and coefficients

function ff_neon_yuv420_bgr24, export=1
    @ load data into registers
    vld2.8 {q1},    [r0, :128] @ Y, split into registers for even/odd pixels
    vld1.32 {d6},    [r1, :64]  @ U
    vld1.32 {d8},    [r2, :64]  @ V

    ldr r0, [sp]            @ extra parameter
    vld1.16 {q0},    [r0]   @ loads 8x16-bit scalars: oy, oc, cy, crv, cbu, cgu, cgv, pad

    @ process each YUV pixel by the following:
    @ X' = X*8 - Xoffset

    vshll.u8 q2, d3, #3
    vshll.u8 q1, d2, #3
    vdup.u16 q5, d0[0]
    vqsub.u16 q1, q1, q5
    vqsub.u16 q2, q2, q5

    vmull.u16 q5, d2, d0[2]
    vmull.u16 q6, d3, d0[2]
    vmull.u16 q7, d4, d0[2]
    vmull.u16 q8, d5, d0[2]

    @ narrow by 13. why 13? trial and error
    vqshrn.u32 d2, q5, #13
    vqshrn.u32 d3, q6, #13
    vqshrn.u32 d4, q7, #13
    vqshrn.u32 d5, q8, #13

    @ luma packing
    @vqshrn.u16 d2, q1, #3
    @vqshrn.u16 d3, q2, #3
    @vzip.u8 d2, d3

    @ chroma
    vshll.u8 q3, d6, #3
    vshll.u8 q4, d8, #3
    vdup.u16 q5, d0[1]
    vqsub.u16 q3, q3, q5  @ U'
    vqsub.u16 q4, q4, q5  @ V'

    @ V' * Vred
    vmull.u16 q7, d8, d0[3]
    vmull.u16 q8, d9, d0[3]
    vqshrn.u32 d14, q7, #13
    vqshrn.u32 d15, q8, #13

    @ add up those motherfuckers
    vqadd.u16 q8, q1, q7
    vqadd.u16 q9,  q2, q7
    vqshrn.u16 d26, q8, #3
    vqshrn.u16 d27, q9, #3
    vzip.u8 d26, d27

    @ U' * Ublue
    vmull.u16 q5, d6, d1[0]
    vmull.u16 q6, d7, d1[0]
    vqshrn.u32 d10, q5, #13
    vqshrn.u32 d11, q6, #13

    vqadd.u16 q6, q1, q5
    vqadd.u16 q7, q2, q5
    vqshrn.u16 d30, q6, #3
    vqshrn.u16 d31, q7, #3
    vzip.u8 d30, d31

    @ U' * Ugreen
    vmull.u16 q5, d6, d1[1]
    vmull.u16 q6, d7, d1[1]
    vqshrn.s32 d10, q5, #13
    vqshrn.s32 d11, q6, #13

    @ V' * Vgreen
    vmull.s16 q7, d8, d1[2]
    vmull.s16 q8, d9, d1[2]
    vqshrn.s32 d14, q7, #13
    vqshrn.s32 d15, q8, #13

    @ compose Green
    vqadd.s16 q7, q5, q7
    vqadd.s16 q8, q1, q7
    vqadd.s16 q9, q2, q7
    vqshrn.u16 d28, q8, #3
    vqshrn.u16 d29, q9, #3
    vzip.u8 d28, d29

    @ useles chroma shift
    vqshrn.u16 d6, q3, #3
    vqshrn.u16 d8, q4, #3

    @veor q14, q14, q14
    @veor q13, q13, q13
    @veor q15, q15, q15

    vst3.8 {d26, d28, d30}, [r3, :64]!
    vst3.8 {d27, d29, d31}, [r3, :64]

    bx lr
endfunc
