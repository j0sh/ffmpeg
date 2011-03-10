#include "asm.S"

@ ff_neon_yuv420_bgr24(uint8_t *Y, uint8_t *U, uint8_t *V, uint8_t *out,
@                      uint64_t *coeffs)

function ff_neon_yuv420_bgr24, export=1
    @ load data into registers
    vld2.32 {q0-q1}, [r0, :128] @split Y into even/odd registers
    vld1.32 {q3},    [r1, :128] @
    vld1.32 {q4},    [r2, :128]
    pop     {r0}                @ extra parameter 

    vld1.64 {d10-d11},[r0]  @ get coefficients
    vst1.64 {d10-d11},[r3]  @ just testing

    @ calculate coeffs
    @ multiply by -1, add to, barrel-shift register by 3
    bx lr
endfunc
