#include "libswscale/swscale.h"
#include "libswscale/swscale_internal.h"

#ifdef HAVE_NEON
static void neon_yuv420_bgr24(uint8_t *Y, uint8_t *U, uint8_t *V, uint8_t *out,
                            int w, uint32_t *coeffs)
{
}

static void neon_yuv420_rgb24(uint8_t *Y, uint8_t *U, uint8_t *V, uint8_t *out,
                            int w, uint32_t *coeffs)
{
}

SwsFunc ff_yuv2rgb_init_neon(SwsContext *c)
{
    if (!(c->flags & SWS_CPU_CAPS_NEON)) return NULL;

    av_log(c, AV_LOG_INFO, "NEON accelerated color space converter: %s->%s\n",
           sws_format_name(c->srcFormat), sws_format_name(c->dstFormat));

    switch (c->dstFormat) {
    case PIX_FMT_RGB24: return neon_yuv420_rgb24;
    case PIX_FMT_BGR24: return neon_yuv420_bgr24;
    default: return NULL;
    }
}
#endif
