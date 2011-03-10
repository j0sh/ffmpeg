#include "libswscale/swscale.h"
#include "libswscale/swscale_internal.h"

#ifdef HAVE_NEON

void ff_neon_yuv420_bgr24(const uint8_t *y, const uint8_t*u, const uint8_t*v,
                          uint8_t*out, uint64_t *coeffs);
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
    ff_neon_yuv420_bgr24(src[0], src[1], src[2], dst[0], &c->yCoeff);

    av_log(NULL, AV_LOG_ERROR, "yCoeff: %llu, recevied %llu\n", c->yCoeff, (uint64_t)dst[0]);
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

    av_log(c, AV_LOG_INFO, "NEON accelerated color space converter: %s->%s\n",
           sws_format_name(c->srcFormat), sws_format_name(c->dstFormat));

    switch (c->dstFormat) {
    case PIX_FMT_RGB24:
    case PIX_FMT_BGR24: return neon_yuv420_bgr24;
    default: return NULL;
    }
}
#endif
