#include "libswscale/swscale.h"
#include "libswscale/swscale_internal.h"

#ifdef HAVE_NEON

void ff_neon_yuv420_bgr24(uint8_t *y, uint8_t*u, uint8_t*v,
                          uint8_t*out, int16_t *scalars);

static void neon_set_scalars(SwsContext *c)
{
    // truncate scalars down to 16bit
    c->neon_scalars.oy  = c->yOffset;
    c->neon_scalars.oc  = c->uOffset;
    c->neon_scalars.cy  = c->yCoeff;
    c->neon_scalars.crv = c->vrCoeff;
    c->neon_scalars.cgu = c->ugCoeff;
    c->neon_scalars.cgv = c->vgCoeff;
    c->neon_scalars.cbu = c->ubCoeff;
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
    uint8_t *srcy = src[0], *srcu = src[1], *srcv = src[2], *u, *v;
    uint8_t *dstrgb = dst[0];

    //assert(!(srcStride[0] & 15)); // ensure its cleanly divisible
#define STRIDE 16

    for (j = 0; j < sliceH; j++) {
        if (j & 1) {
            srcu += srcStride[1];
            srcv += srcStride[2];
        }
        u = srcu; v = srcv;
        for (i = 0; i < srcStride[0]; i+= STRIDE) {
            ff_neon_yuv420_bgr24(srcy, u, v, dstrgb, &c->neon_scalars);
            dstrgb += STRIDE*3;
            srcy += STRIDE;
            u += 8; v += 8;
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
