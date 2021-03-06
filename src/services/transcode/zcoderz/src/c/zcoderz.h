#ifndef ZCODERZ_VPX_H
#define ZCODERZ_VPX_H


#define VPX_CODEC_DISABLE_COMPAT 1

#include <stdio.h>

#include <vpx/vpx_decoder.h>
#include <vpx/vp8dx.h>

// #define IVF_FILE_HDR_SZ  (32)
// #define IVF_FRAME_HDR_SZ (12)


typedef struct {
  VpxVideoStreamReader *reader;
  const VpxVideoInfo *info;
  const VpxInterface *decoder;

  size_t net_packet_size;

  size_t net_buf_fill;
  size_t net_buf_size;
  uint8_t *net_buf;

  vpx_codec_iter_t iter;
  vpx_codec_ctx_t codec;
  vp8_postproc_cfg_t postproc;

  vpx_image_t *vpx_img;
} Stream;

void version();
Stream* create_stream(uint8_t *header, size_t net_packet_size, size_t net_buf_size);
size_t stream_width(Stream *stream);
size_t stream_height(Stream *stream);
uint8_t destroy_stream(Stream *stream);
float stream_get_buff_fill(Stream *stream);
uint8_t stream_flush(Stream *stream);
uint8_t stream_seek(Stream *stream, size_t index);
uint8_t stream_write(Stream *stream, const uint8_t *data, const size_t data_size);
uint8_t stream_write_chunk(Stream *stream, const uint8_t *data, const size_t data_size);
uint8_t stream_parse(Stream *stream, uint8_t *gl_rgb_buf, size_t *net_bytes_read);
uint8_t stream_parse_yuv(Stream *stream, uint8_t *gl_luma_buf, uint8_t *gl_chromaB_buf, uint8_t *gl_chromaR_buf, size_t *net_bytes_read);

#endif
