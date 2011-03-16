#include "libswscale/swscale.h"
#include "libswscale/swscale_internal.h"

#ifdef HAVE_NEON

void ff_neon_yuv420_bgr24(uint8_t *y, uint8_t*u, uint8_t*v,
                          uint8_t*out, int16_t *scalars);

static void neon_set_scalars(SwsContext *c)
{
    // truncate scalars down to 16bit
    c->oy  = (c->yOffset & 0xffff) >> 3; // c->yOffset has been pre-multiplied by 8
    c->oc  = 128;
    c->cy  = c->yCoeff;
    c->crv = c->vrCoeff;
    c->cbu = c->ubCoeff;
    c->cgu = c->ugCoeff;
    c->cgv = c->vgCoeff;
    av_log(NULL, 0, "cy %d crv %d cbu %d cgu %d cgv %d\n", c->cy >> 3, c->crv >> 3, c->cbu >> 3, c->cgu >> 3, c->cgv >> 3);
}

static int neon_yuv420_bgr24(SwsContext *c, const uint8_t *src[], int srcStride[],
                           int sliceY, int sliceH, uint8_t *dst[], int dstStride[])
{
    /*
        R = Y' * Ycoef + Vred   * V'
        G = Y' * Ycoef + Vgreen * V' + Ugreen * U'
        B = Y' * Ycoef               + Ublue  * U'

        Where
        X' = X * 8 - Xoffset
     */
    int i, j;
    uint8_t *srcy = src[0], *srcu = src[1], *srcv = src[2];
    uint8_t *dstrgb = dst[0];

    //assert(!(srcStride[0] & 15)); // ensure its cleanly divisible
    av_log(NULL, 0, "sliceH %d, srcH %d\n", sliceH, c->srcH);

    for (j = 0; j < sliceH; j++) {
    for (i = 0; i < srcStride[0]; i+= 16) {

        ff_neon_yuv420_bgr24(srcy, srcu, srcv, dstrgb, &c->oy);
        dstrgb += 16*3;
        srcy += 16;
        srcu += 8; srcv += 8;
    }
    }

    return sliceH;
}

static int neon_yuv420_rgb24(SwsContext *c, const uint8_t *sr[], int srcStride[],
                          int sliceY, int sliceH, uint8_t *dst[], int dstStride[])
{
    return sliceH;
}

SwsFunc ff_yuv2rgb_init_neon(SwsContext *c)
{
    if (!(c->flags & SWS_CPU_CAPS_NEON)) return NULL;

    neon_set_scalars(c);

    av_log(c, AV_LOG_INFO, "NEON accelerated color space converter: %s->%s\n",
           sws_format_name(c->srcFormat), sws_format_name(c->dstFormat));

    switch (c->dstFormat) {
    case PIX_FMT_RGB24:
    case PIX_FMT_BGR24: return neon_yuv420_bgr24;
    default: return NULL;
    }
}
#endif
