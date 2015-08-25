
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include <vpx/vpx_decoder.h>
#include <vpx/vp8dx.h>

#include <tools_common.h>
#include <video_stream_reader.h>
#include <vpx_config.h>
#include <libyuv/convert_from.h>

#include "zcoderz.h"

void version() {
  printf("v0.0.1\r\n");
}

void usage_exit(void) {
  exit(EXIT_FAILURE);
}

Stream* create_stream(uint8_t *header, size_t net_packet_size, size_t net_buf_size) {
  Stream *stream = (Stream*)malloc(sizeof(Stream));

  size_t *size_t_ptr;
  uint8_t *uint8_t_ptr;

  // printf("size_t* %u\n", sizeof(size_t_ptr));
  // printf("uint8_t* %u\n", sizeof(uint8_t_ptr));
  // printf("size_t %u\n", sizeof(*size_t_ptr));
  // printf("uint8_t %u\n", sizeof(*uint8_t_ptr));

  stream->net_packet_size = net_packet_size;
  stream->net_buf_fill = 0;
  stream->net_buf_size = net_buf_size;
  proc_info("Net Buf Size %u", (unsigned int)stream->net_buf_size);
  stream->net_buf = (uint8_t*)calloc(stream->net_buf_size, sizeof(uint8_t));

  stream->reader = vpx_video_stream_reader_open(header);
  if (!stream->reader)
    proc_die("Failed to create new stream");

  stream->info = vpx_video_stream_reader_get_info(stream->reader);
  proc_info("Frame Width %u\n", stream->info->frame_width);
  proc_info("Frame Height %u\n", stream->info->frame_height);
  // proc_info("Frame Count %u\n", stream->info->frame_count);

  // stream->gl_rgb_buf_fill = 0;
  // stream->gl_rgb_buf_size = stream->info->frame_width * stream->info->frame_height * 3;
  // // proc_info("GL Buf Size %u", (unsigned int)stream->gl_buf_size);
  // stream->gl_rgb_buf = (uint8_t*)malloc(stream->gl_rgb_buf_size * sizeof(uint8_t));
  //
  // stream->gl_luma_buf_fill = 0;
  // stream->gl_luma_buf_size = stream->info->frame_width * stream->info->frame_height;
  // // proc_info("GL Buf Size %u", (unsigned int)stream->gl_buf_size);
  // stream->gl_luma_buf = (uint8_t*)calloc(stream->gl_luma_buf_size, sizeof(uint8_t));
  //
  // stream->gl_chromaB_buf_fill = 0;
  // stream->gl_chromaB_buf_size = stream->info->frame_width/2 * stream->info->frame_height/2;
  // // proc_info("GL Buf Size %u", (unsigned int)stream->gl_buf_size);
  // stream->gl_chromaB_buf = (uint8_t*)calloc(stream->gl_chromaB_buf_size, sizeof(uint8_t));
  //
  // stream->gl_chromaR_buf_fill = 0;
  // stream->gl_chromaR_buf_size = stream->info->frame_width/2 * stream->info->frame_height/2;
  // // proc_info("GL Buf Size %u", (unsigned int)stream->gl_buf_size);
  // stream->gl_chromaR_buf = (uint8_t*)calloc(stream->gl_chromaR_buf_size, sizeof(uint8_t));

  stream->decoder = get_vpx_decoder_by_fourcc(stream->info->codec_fourcc);
  if (!stream->decoder)
    proc_die("Unknown input codec.");

  printf("Using %s\r\n", vpx_codec_iface_name(stream->decoder->codec_interface()));

  if (vpx_codec_dec_init(&stream->codec, stream->decoder->codec_interface(), NULL, 0))
    die_codec(&stream->codec, "Failed to initialize decoder.");

  stream->postproc = (vp8_postproc_cfg_t){
    VP8_DEBLOCK | VP8_DEMACROBLOCK,
    4, // strength of deblocking, valid range [0, 16]
    0
  };

  if(vpx_codec_control(&stream->codec, VP8_SET_POSTPROC, &stream->postproc))
    die_codec(&stream->codec, "Failed to turn on postproc");

  return stream;
}

uint8_t destroy_stream(Stream *stream) {
  if (stream) {
    if (stream->reader)
      vpx_video_stream_reader_close(stream->reader);
    free(stream);

    if (stream->net_buf)
      free(stream->net_buf);

    return 0;
  }
  return 1;
}

uint8_t stream_flush(Stream *stream) {
  if (stream) {
    stream->net_buf_fill = 0;
    // memset(stream->net_buf, 0, stream->net_buf_size);
    return 0;
  }
  return 1;
}

uint8_t stream_seek(Stream *stream, size_t index) {
  // printf("Index %u\r\n", (unsigned int)index);
  // printf("Buff Fill %u\r\n", (unsigned int)stream->net_buf_fill);
  uint8_t *net_buf = malloc(sizeof(uint8_t) * stream->net_buf_size);
  size_t u, i = index;
  if ((int)stream->net_buf_size - (int)index >= 0) {
    memcpy(net_buf, stream->net_buf + index, stream->net_buf_size - index);
    free(stream->net_buf);
    stream->net_buf = net_buf;
    stream->net_buf_fill = stream->net_buf_fill - index;
    // printf("Post Buff Fill %u\r\n", (unsigned int)stream->net_buf_fill);
    return 0;
  }
  return 1;
  // return !stream_write(stream, stream->net_buf + index, index);
}

uint8_t stream_write(Stream *stream, const uint8_t *data, const size_t data_size) {
  if (data_size < stream->net_buf_size) {
    memcpy(stream->net_buf, data, data_size);
    stream->net_buf_fill = data_size;
    return 0;
  } else {
    printf("Write chunk triggered realloc\r\n");
    stream->net_buf_size *= 2;
    uint8_t *net_buf = malloc(sizeof(uint8_t) * stream->net_buf_size);
    memcpy(net_buf, stream->net_buf, stream->net_buf_fill);
    free(stream->net_buf);
    stream->net_buf = net_buf;
    return stream_write(stream, data, data_size);
  }
}

uint8_t stream_write_chunk(Stream *stream, const uint8_t *data, const size_t data_size) {
  // printf("Size %u\n", (unsigned int)data_size);
  if (stream->net_buf_fill + data_size <= stream->net_buf_size) {
    memcpy(stream->net_buf + stream->net_buf_fill, data, data_size);
    stream->net_buf_fill += data_size;
    return 0;
  } else {
    printf("Write chunk triggered realloc\r\n");
    stream->net_buf_size *= 2;
    uint8_t *net_buf = malloc(sizeof(uint8_t) * stream->net_buf_size);
    memcpy(net_buf, stream->net_buf, stream->net_buf_fill);
    free(stream->net_buf);
    stream->net_buf = net_buf;
    return stream_write_chunk(stream, data, data_size);
  }
}

uint8_t stream_parse(Stream *stream, uint8_t *gl_rgb_buf, size_t *net_bytes_read) {
  *net_bytes_read = 0;
  if (vpx_video_stream_reader_read_frame(stream->net_buf, stream->net_buf_fill, stream->reader)) {
    size_t frame_size = 0;
    const unsigned char *frame = vpx_video_stream_reader_get_frame(stream->reader, &frame_size);
    *net_bytes_read = frame_size + 12;
    // proc_info("Read Frame from Steam");
    // proc_info("VPX Frame Size %u", (unsigned int)stream->vpx_frame_size);
    if (vpx_codec_decode(&stream->codec, frame, (unsigned int)frame_size, NULL, 0))
      proc_warn("Failed to decode frame"); // die_codec(&stream->codec, "Failed to decode frame");

    // proc_info("Decoded Frame");
    vpx_image_t *img = NULL;
    stream->iter = NULL;
    while ((img = vpx_codec_get_frame(&stream->codec, &stream->iter)) != NULL) {
      // proc_info("Got frame Image");
      // proc_info("Y Stride - %u, U Stride - %u, V Stride %u", img->stride[0], img->stride[1], img->stride[2]);
      // proc_info("Image Format %u", (size_t)img->fmt);
      // switch ((size_t)img->fmt) {
      //   case (size_t)VPX_IMG_FMT_PLANAR:
      //     proc_info("VPX_IMG_FMT_PLANAR");
      //     break;
      //   case (size_t)VPX_IMG_FMT_I420:
      //     proc_info("VPX_IMG_FMT_I420");
      //     break;
      //   case (size_t)VPX_IMG_FMT_I422:
      //     proc_info("VPX_IMG_FMT_I422");
      //     break;
      //   case (size_t)VPX_IMG_FMT_I444:
      //     proc_info("VPX_IMG_FMT_I444");
      //     break;
      //   default:
      //     proc_info("Unknown VPX IMG_FMT");
      //     break;
      // }
      // stream->gl_luma_buf = img->planes[0]; // y
      // stream->gl_chromaB_buf = img->planes[1]; // u
      // stream->gl_chromaR_buf = img->planes[2]; // v

      int status = I420ToRGB24(img->planes[0], img->stride[0],
        img->planes[1], img->stride[1],
        img->planes[2], img->stride[2],
        gl_rgb_buf, img->d_w * 3,
        img->d_w, img->d_h);

      // proc_info("I420ToRGB24 to status - %i", status);
      return 0;
    }
  }
  return 1;
}
