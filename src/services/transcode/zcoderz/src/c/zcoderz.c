
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <vpx/vpx_decoder.h>

#include <tools_common.h>
#include <video_stream_reader.h>
#include <vpx_config.h>

#include "zcoderz.h"

void version() {
  printf("v0.0.1\r\n");
}

void usage_exit(void) {
  exit(EXIT_FAILURE);
}

Stream* create_stream(uint8_t *header, size_t net_packet_size, size_t gl_buf_size) {
  Stream *stream = (Stream*)malloc(sizeof(Stream));

  stream->net_packet_size = net_packet_size;
  stream->net_buf_fill = 0;
  stream->net_buf_size = net_packet_size * 4;
  proc_info("Net Buf Size %u", (unsigned int)stream->net_buf_size);
  stream->net_buf = (uint8_t*)malloc(sizeof(uint8_t) * stream->net_buf_size);

  stream->gl_buf_fill = 0;
  stream->gl_buf_size = gl_buf_size;
  proc_info("GL Buf Size %u", (unsigned int)stream->gl_buf_size);
  stream->gl_buf = (uint8_t*)malloc(sizeof(uint8_t) * stream->gl_buf_size);

  stream->reader = vpx_video_stream_reader_open(header);
  if (!stream->reader)
    proc_die("Failed to create new stream");

  stream->info = vpx_video_stream_reader_get_info(stream->reader);
  proc_info("Frame Width %u\n", stream->info->frame_width);
  proc_info("Frame Height %u\n", stream->info->frame_height);
  proc_info("Frame Count %u\n", stream->info->frame_count);

  stream->decoder = get_vpx_decoder_by_fourcc(stream->info->codec_fourcc);
  if (!stream->decoder)
    proc_die("Unknown input codec.");

  printf("Using %s\r\n", vpx_codec_iface_name(stream->decoder->codec_interface()));

  if (vpx_codec_dec_init(&stream->codec, stream->decoder->codec_interface(), NULL, 0))
    die_codec(&stream->codec, "Failed to initialize decoder.");

  return stream;
}

uint8_t destroy_stream(Stream *stream) {
  if (stream) {
    if (stream->reader)
      vpx_video_stream_reader_close(stream->reader);
    free(stream);

    if (stream->net_buf)
      free(stream->net_buf);

    if (stream->gl_buf)
      free(stream->gl_buf);

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

uint8_t stream_write(Stream *stream, uint8_t *data, size_t data_size) {
  if (data_size < stream->net_buf_size) {
    memcpy(stream->net_buf, data, data_size);
    stream->net_buf_fill = data_size;
    return 0;
  } else {
    stream->net_buf_size *= 2;
    stream->net_buf = (uint8_t*)realloc(stream->net_buf, sizeof(uint8_t) * stream->net_buf_size);
    stream_write(stream, data, data_size);
    return 1;
  }
}

uint8_t stream_write_chunk(Stream *stream, uint8_t *data, size_t data_size) {
  if (stream->net_buf_fill + data_size < stream->net_buf_size) {
    memcpy(stream->net_buf + stream->net_buf_fill, data, data_size);
    stream->net_buf_fill += data_size;
    return 0;
  }
  return 1;
}

uint8_t stream_get_frame(Stream *stream, const uint8_t *gl_buf, const size_t *gl_buf_size) {
  if (vpx_video_stream_reader_read_frame(stream->net_buf, stream->net_buf_fill, stream->reader)) {

    // const unsigned char *frame = vpx_video_reader_get_frame(reader, frame_size);
    stream->vpx_frame = vpx_video_stream_reader_get_frame(stream->reader, &stream->vpx_frame_size);

    proc_info("VPX Frame Size %u", (unsigned int)stream->vpx_frame_size);
    if (vpx_codec_decode(&stream->codec, stream->vpx_frame, (unsigned int)stream->vpx_frame_size, NULL, 0))
      die_codec(&stream->codec, "Failed to decode frame.");

    while ((stream->vpx_img = vpx_codec_get_frame(&stream->codec, &stream->iter)) != NULL) {
      if (stream->vpx_img) {
        vpx_image_t *img = stream->vpx_img;
        const int w = img->d_w;
        const int w2 = w/2;
        const int pstride = w*3;
        const int h = img->d_h;
        const int h2 = h/2;

        const int img_size = w*h*3;
        if (stream->gl_buf_size < img_size) {
          stream->gl_buf_size = img_size;
          stream->gl_buf = (unsigned char *)realloc(stream->gl_buf, stream->gl_buf_size);
        }
        // *gl_buf_fill = img_size;

        const int strideY = img->stride[0];
        const int strideU = img->stride[1];
        const int strideV = img->stride[2];
        // const int strideA = img->stride[2];

        int posy, posx;
        for (posy = 0; posy < h2; posy++) {
            unsigned char *dst = stream->gl_buf + pstride * (posy * 2);
            unsigned char *dst2 = stream->gl_buf + pstride * (posy * 2 + 1);

            const unsigned char *srcY = img->planes[0] + strideY * posy * 2;
            const unsigned char *srcY2 = img->planes[0] + strideY * (posy * 2 + 1);
            const unsigned char *srcU = img->planes[1] + strideU * posy;
            const unsigned char *srcV = img->planes[2] + strideV * posy;
            // const unsigned char *srcA = img->planes[3] + strideA * posy;

            for (posx = 0; posx < w2; posx++) {
                unsigned char Y,U,V;

                U = *(srcU++);
                V = *(srcV++);

                Y = *(srcY++);
                *(dst++) = U; *(dst++) = V; *(dst++) = Y;

                Y = *(srcY2++);
                *(dst2++) = U; *(dst2++) = V; *(dst2++) = Y;

                Y = *(srcY++);
                *(dst++) = U; *(dst++) = V; *(dst++) = Y;

                Y = *(srcY2++);
                *(dst2++) = U; *(dst2++) = V; *(dst2++) = Y;
            }
        }
        // memcpy(stream->buf + stream->buf_fill, data, data_size);
      }
      // vpx_img_write(img, outfile);
    }
    gl_buf = stream->gl_buf;
    gl_buf_size = &stream->gl_buf_size;
    return 0;
  }
  return 1;
}

// void do_things() {
//   int frame_cnt = 0;
//   FILE *outfile = NULL;
//   vpx_codec_ctx_t codec;
//   VpxVideoReader *reader = NULL;
//   const VpxInterface *decoder = NULL;
//   const VpxVideoInfo *info = NULL;
//
//   exec_name = "llama";
//
//   reader = vpx_video_reader_open("test_in.webm");
//   if (!reader)
//     proc_die("Failed to open %s for reading.", "test_in.webm");
//
//   if (!(outfile = fopen("test_out.webm", "wb")))
//     proc_die("Failed to open %s for writing.", "test_out.webm");
//
//   info = vpx_video_reader_get_info(reader);
//
//   decoder = get_vpx_decoder_by_fourcc(info->codec_fourcc);
//   if (!decoder)
//     proc_die("Unknown input codec.");
//
//   printf("Using %s\n", vpx_codec_iface_name(decoder->codec_interface()));
//
//   if (vpx_codec_dec_init(&codec, decoder->codec_interface(), NULL, 0))
//     die_codec(&codec, "Failed to initialize decoder.");
//
//   while (vpx_video_reader_read_frame(reader)) {
//     vpx_codec_iter_t iter = NULL;
//     vpx_image_t *img = NULL;
//     size_t frame_size = 0;
//     const unsigned char *frame = vpx_video_reader_get_frame(reader,
//                                                             &frame_size);
//     if (vpx_codec_decode(&codec, frame, (unsigned int)frame_size, NULL, 0))
//       die_codec(&codec, "Failed to decode frame.");
//
//     while ((img = vpx_codec_get_frame(&codec, &iter)) != NULL) {
//       vpx_img_write(img, outfile);
//       ++frame_cnt;
//     }
//   }
//
//   printf("Processed %d frames.\n", frame_cnt);
//   if (vpx_codec_destroy(&codec))
//     die_codec(&codec, "Failed to destroy codec");
//
//   printf("Play: ffplay -f rawvideo -pix_fmt yuv420p -s %dx%d %s\n",
//          info->frame_width, info->frame_height, "test_out.webm");
//
//   vpx_video_reader_close(reader);
//
//   fclose(outfile);
// }