#ifndef PLAYVPX_H
#define PLAYVPX_H

// #ifdef PLAYVPX_SDL
// #include "SDL/SDL.h"
// #include "SDL/SDL_opengl.h"
// #endif
//
// #ifdef PLAYVPX_CUZCODE
// #include "cuz_opengl.h"
// #endif

#define VPX_CODEC_DISABLE_COMPAT 1

#include <stdio.h>

#include <vpx/vpx_decoder.h>
#include <vpx/vp8dx.h>

#define IVF_FILE_HDR_SZ  (32)
#define IVF_FRAME_HDR_SZ (12)


typedef int bool;
#define true 1
#define false 0

typedef struct {
    int is_init;
    char fname[512];
    int state;
    unsigned char *pixels;
    // GLuint texture;

    FILE *infile;
    vpx_codec_ctx_t  codec;
    int              flags, frame_cnt;
    unsigned char    file_hdr[IVF_FILE_HDR_SZ];
    unsigned char    frame_hdr[IVF_FRAME_HDR_SZ];
    unsigned char    frame[256*1024];
    vpx_codec_err_t  res;

    int               frame_sz;
    vpx_codec_iter_t  iter;
    vpx_image_t      *img;

} Vpxdata;

void playvpx_init(Vpxdata *data, const char *_fname);

bool playvpx_loop(Vpxdata *data);

// int playvpx_get_texture(Vpxdata *data);

void playvpx_deinit(Vpxdata *data);

#endif
