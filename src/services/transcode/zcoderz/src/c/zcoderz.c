
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include <vpx/vpx_decoder.h>
#include <vpx/vp8dx.h>

#include <tools_common.h>
#include <video_stream_reader.h>
#include <vpx_config.h>

#include "zcoderz.h"

#ifndef max
#define max(a,b)            (((a) > (b)) ? (a) : (b))
#endif

#ifndef min
#define min(a,b)            (((a) < (b)) ? (a) : (b))
#endif


// The kernel size affects quality of the filtered result. Beyond 8,
// there are diminishing returns but 4 is noticeably inferior to 8.
// With large kernels such as 32 or even 256, objectionable ringing
// artefacts are more evident (as well as being more costly to compute).
#define KERNEL_SIZE 4

// fixed point scale & round result of matrix multiplication to 0..255
#define SCALEYUV(v) (((v)+128000)/256000)
#define SCALEYUVDIV4(v) (((v)+512000)/1024000)

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
  //
  // printf("size_t %u\n", sizeof(*size_t_ptr));
  // printf("uint8_t %u\n", sizeof(*uint8_t_ptr));

  stream->net_packet_size = net_packet_size;
  stream->net_buf_fill = 0;
  stream->net_buf_size = net_buf_size;
  // proc_info("Net Buf Size %u", (unsigned int)stream->net_buf_size);
  stream->net_buf = (uint8_t*)calloc(stream->net_buf_size, sizeof(uint8_t));

  stream->reader = vpx_video_stream_reader_open(header);
  if (!stream->reader)
    proc_die("Failed to create new stream");

  stream->info = vpx_video_stream_reader_get_info(stream->reader);
  proc_info("Frame Width %u\n", stream->info->frame_width);
  proc_info("Frame Height %u\n", stream->info->frame_height);
  // proc_info("Frame Count %u\n", stream->info->frame_count);

  stream->gl_rgb_buf_fill = 0;
  stream->gl_rgb_buf_size = stream->info->frame_width * stream->info->frame_height * 3;
  // proc_info("GL Buf Size %u", (unsigned int)stream->gl_buf_size);
  stream->gl_rgb_buf = (uint8_t*)calloc(stream->gl_rgb_buf_size, sizeof(uint8_t));

  stream->gl_luma_buf_fill = 0;
  stream->gl_luma_buf_size = stream->info->frame_width * stream->info->frame_height;
  // proc_info("GL Buf Size %u", (unsigned int)stream->gl_buf_size);
  stream->gl_luma_buf = (uint8_t*)calloc(stream->gl_luma_buf_size, sizeof(uint8_t));

  stream->gl_chromaB_buf_fill = 0;
  stream->gl_chromaB_buf_size = stream->info->frame_width/2 * stream->info->frame_height/2;
  // proc_info("GL Buf Size %u", (unsigned int)stream->gl_buf_size);
  stream->gl_chromaB_buf = (uint8_t*)calloc(stream->gl_chromaB_buf_size, sizeof(uint8_t));

  stream->gl_chromaR_buf_fill = 0;
  stream->gl_chromaR_buf_size = stream->info->frame_width/2 * stream->info->frame_height/2;
  // proc_info("GL Buf Size %u", (unsigned int)stream->gl_buf_size);
  stream->gl_chromaR_buf = (uint8_t*)calloc(stream->gl_chromaR_buf_size, sizeof(uint8_t));

  stream->decoder = get_vpx_decoder_by_fourcc(stream->info->codec_fourcc);
  if (!stream->decoder)
    proc_die("Unknown input codec.");

  printf("Using %s\r\n", vpx_codec_iface_name(stream->decoder->codec_interface()));

  if (vpx_codec_dec_init(&stream->codec, stream->decoder->codec_interface(), NULL, 0))
    die_codec(&stream->codec, "Failed to initialize decoder.");

  // stream->postproc = (vp8_postproc_cfg_t){
  //   VP8_DEBLOCK | VP8_DEMACROBLOCK,
  //   4, // strength of deblocking, valid range [0, 16]
  //   0
  // };
  //
  // if(vpx_codec_control(&stream->codec, VP8_SET_POSTPROC, &stream->postproc))
  //   die_codec(&stream->codec, "Failed to turn on postproc");

  return stream;
}

uint8_t destroy_stream(Stream *stream) {
  if (stream) {
    if (stream->reader)
      vpx_video_stream_reader_close(stream->reader);
    free(stream);

    if (stream->net_buf)
      free(stream->net_buf);

    if (stream->gl_luma_buf)
      free(stream->gl_luma_buf);

    if (stream->gl_chromaB_buf)
      free(stream->gl_chromaB_buf);

    if (stream->gl_chromaR_buf)
      free(stream->gl_chromaR_buf);

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
  printf("Index %u\r\n", (unsigned int)index);
  return !stream_write(stream, stream->net_buf + index, index);
}

uint8_t stream_write(Stream *stream, const uint8_t *data, const size_t data_size) {
  if (data_size < stream->net_buf_size) {
    memcpy(stream->net_buf, data, data_size);
    stream->net_buf_fill = data_size;
    return 0;
  } else {
    stream->net_buf_size *= 2;
    stream->net_buf = (uint8_t*)realloc(stream->net_buf, sizeof(uint8_t) * stream->net_buf_size);
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
    stream->net_buf = (uint8_t*)realloc(stream->net_buf, sizeof(uint8_t) * stream->net_buf_size);
    return stream_write_chunk(stream, data, data_size);
  }
}

// conversion per http://www.poynton.com/notes/colour_and_gamma/ColorFAQ.html#RTFToC30
static int rcoeff(int y, int u, int v){ return 298082*y +      0*u + 408583*v; }
static int gcoeff(int y, int u, int v){ return 298082*y - 100291*u - 208120*v; }
static int bcoeff(int y, int u, int v){ return 298082*y + 516411*u +      0*v; }

int clamp(int vv){
	if(vv < 0)
		return 0;
	else if(vv > 255)
		return 255;
	return vv;
}

// This was very helpful in understanding Lanczos kernel and convolution:
// http://stackoverflow.com/questions/943781/where-can-i-find-a-good-read-about-bicubic-interpolation-and-lanczos-resampling/946943#946943

static double sinc(double x){ return sin(x)/x; }

// build 1-D kernel
// conv: array of 2n+1 floats (-n .. 0 .. +n)
void lanczos_1d(double *conv, unsigned n, double fac){
	unsigned i;

	conv[n] = 1.;
	for(i = 1; i <= n; ++i){
		double xpi = i*M_PI*fac;
		conv[n+i] = conv[n-i] = sinc(xpi)*sinc(xpi/n);
	}
}

uint8_t lanczos_interp2(unsigned char *in, unsigned char *out, int in_stride, int out_w, int out_h){
	double conv[2*KERNEL_SIZE+1], *knl, sum, weight;
	float *t_buf, *t_row;
	int i, j, d, k, x, y, in_w = (out_w+1)/2, in_h = (out_h+1)/2;
	unsigned char *in_row, *out_row;

	lanczos_1d(conv, KERNEL_SIZE, 0.5);
	knl = conv + KERNEL_SIZE; // zeroth index

	// apply horizontal convolution, interpolating input to output 1:2
	// store this in a temporary buffer, with same row count as input
	// (This code is completely un-optimised, apart from precomputing the kernel, above.)

	if((t_buf = malloc(sizeof(*t_buf) * in_h * out_w)))
		return 1;

	for(j = 0, in_row = in, t_row = t_buf; j < in_h; ++j, in_row += in_stride, t_row += out_w){
		for(i = 0; i < out_w; ++i){
			d = i % 2;

			// find involved input pixels. multiply each by corresponding
			// kernel coefficient.

			sum    = d ? 0. : knl[0]*in_row[i/2];
			weight = d ? 0. : knl[0];
			// step out from the zero point, in relative output ordinates
			for(k = 2-d; k <= KERNEL_SIZE; k += 2){
				x = (i-k)/2;
				if(x >= 0){
					sum += knl[k]*in_row[x];
					weight += knl[k];
				}
				x = (i+k)/2;
				if(x < in_w){
					sum += knl[k]*in_row[x];
					weight += knl[k];
				}
			}
			t_row[i] = sum/weight;
		}
	}

	// interpolate vertically
	for(i = 0; i < out_w; ++i){
		t_row = t_buf + i;
		out_row = out + i;
		for(j = 0; j < out_h; ++j){
			d = j % 2;

			// find involved input pixels. multiply each by corresponding
			// kernel coefficient.

			sum    = d ? 0. : knl[0]*t_row[out_w*j/2];
			weight = d ? 0. : knl[0];
			// step out from the zero point, in relative output ordinates
			for(k = 2-d; k <= KERNEL_SIZE; k += 2){
				y = (j-k)/2;
				if(y >= 0){
					sum += knl[k]*t_row[out_w*y];
					weight += knl[k];
				}
				y = (j+k)/2;
				if(y < in_h){
					sum += knl[k]*t_row[out_w*y];
					weight += knl[k];
				}
			}
			out_row[0] = clamp(sum/weight + 0.5);

			out_row += out_w; // step down one row
		}
	}

  free(t_buf);
	return 0;
}

inline int clamp8(int v) {
    return min(max(v, 0), 255);
}

uint8_t stream_parse(Stream *stream) {
  if (vpx_video_stream_reader_read_frame(stream->net_buf, stream->net_buf_fill, stream->reader)) {
    // const unsigned char *frame = vpx_video_reader_get_frame(reader, frame_size);
    stream->vpx_frame = vpx_video_stream_reader_get_frame(stream->reader, &stream->vpx_frame_size);

    // proc_info("VPX Frame Size %u", (unsigned int)stream->vpx_frame_size);
    if (vpx_codec_decode(&stream->codec, stream->vpx_frame, (unsigned int)stream->vpx_frame_size, NULL, 0))
      proc_warn("Failed to decode frame"); // die_codec(&stream->codec, "Failed to decode frame");

      while ((stream->vpx_img = vpx_codec_get_frame(&stream->codec, &stream->iter)) != NULL) {
        if (stream->vpx_img) {
        vpx_image_t *img = stream->vpx_img;
        proc_info("Got frame Image");
        proc_info("Y Stride - %u, U Stride - %u, V Stride %u", img->stride[0], img->stride[1], img->stride[2]);
        proc_info("Image Format %u", img->fmt);
        stream->gl_luma_buf = img->planes[0]; // y
        stream->gl_chromaB_buf = img->planes[2]; // u
        stream->gl_chromaR_buf = img->planes[1]; // v

        int i = 0;
        unsigned int imgY, imgX;
        for (imgY = 0; imgY < img->d_h; imgY++) {
          for (imgX = 0; imgX < img->d_w; imgX++) {
            int y = stream->gl_luma_buf[imgY * img->stride[0] + imgX];
            int u = stream->gl_chromaB_buf[(imgY / 2) * img->stride[2] + (imgX / 2)];
            int v = stream->gl_chromaR_buf[(imgY / 2) * img->stride[1] + (imgX / 2)];

            // stream->gl_rgb_buf[i + 0] = (uint8_t)y;
            // stream->gl_rgb_buf[i + 1] = (uint8_t)u;
            // stream->gl_rgb_buf[i + 2] = (uint8_t)v;

            int c = y - 16;
            int d = (u - 128);
            int e = (v - 128);
            //
            // // TODO: adjust colors ?
            //
            int r = clamp8((298 * c           + 409 * e + 128) >> 8);
            int g = clamp8((298 * c - 100 * d - 208 * e + 128) >> 8);
            int b = clamp8((298 * c + 516 * d           + 128) >> 8);
            //
            // // TODO: cast instead of clamp8
            //
            // data[i + 0] = static_cast<uint8_t>(r);
            // data[i + 1] = static_cast<uint8_t>(g);
            // data[i + 2] = static_cast<uint8_t>(b);

            stream->gl_rgb_buf[i + 0] = (uint8_t)r;
            stream->gl_rgb_buf[i + 1] = (uint8_t)g;
            stream->gl_rgb_buf[i + 2] = (uint8_t)b;

            i += 3;
          }
        }

        // uint8_t *rgb, *py, *pu, *pv;
        // unsigned int i, j;
        // py = img->planes[0];
        // pu = img->planes[1];
        // pv = img->planes[2];
        // rgb = stream->gl_rgb_buf;
        // for (j = 0; j < img->d_h; ++j) {
        //   for (i = 0; i < img->d_w; ++i) {
        //     int y = py[i] - 16, u = pu[i/2] - 128, v = pv[i/2] - 128;
        //     // rgb[0] = clamp(SCALEYUV(rcoeff(y, u, v)));
        //     // rgb[1] = clamp(SCALEYUV(gcoeff(y, u, v)));
        //     // rgb[2] = clamp(SCALEYUV(bcoeff(y, u, v)));
        //     rgb[0] = y+ 0 * u + 1.13983 * v;
        //     rgb[1] = y+ -0.39465 * u + -0.58060 * v;
        //     rgb[2] = y+ -0.03211 * u + 0 * v;
        //     rgb += 3;
        //   }
        //   py += img->stride[0];
        //   if (j & 1){
        //     pu += img->stride[1];
        //     pv += img->stride[2];
        //   }
        // }
        return 0;
      }
    }
  }
  return 1;
}

uint8_t stream_parse2(Stream *stream) {
  if (vpx_video_stream_reader_read_frame(stream->net_buf, stream->net_buf_fill, stream->reader)) {

    // const unsigned char *frame = vpx_video_reader_get_frame(reader, frame_size);
    stream->vpx_frame = vpx_video_stream_reader_get_frame(stream->reader, &stream->vpx_frame_size);
    proc_info("VPX Frame Size %u", stream->vpx_frame_size);

    // proc_info("VPX Frame Size %u", (unsigned int)stream->vpx_frame_size);
    if (vpx_codec_decode(&stream->codec, stream->vpx_frame, (unsigned int)stream->vpx_frame_size, NULL, 0))
      proc_warn("Failed to decode frame"); // die_codec(&stream->codec, "Failed to decode frame");

    while ((stream->vpx_img = vpx_codec_get_frame(&stream->codec, &stream->iter)) != NULL) {
      if (stream->vpx_img) {
        unsigned int i, j;
	      uint8_t *rgb, *py, *pu, *pv;
        vpx_image_t *img = stream->vpx_img;

        proc_info("Img Width %u, Height %u", img->d_w, img->d_h);
        // first plane from codec is 1:1 Y (luminance) data
        // second and third planes are 1:2 subsampled U/V
        py = img->planes[0];

        // if((pu = (uint8_t*)malloc(img->d_w*img->d_h))
        // && (pv = (uint8_t*)malloc(img->d_w*img->d_h)) && 0 == 1) {
        //   // high quality 1:2 upsampling of u & v using Lanczos filter
        //   if(!lanczos_interp2(img->planes[1], pu, img->stride[1], img->d_w, img->d_h)
        //   && !lanczos_interp2(img->planes[2], pv, img->stride[2], img->d_w, img->d_h)) {
        //     rgb = stream->gl_buf;
        //     for(j = 0; j < img->d_h; ++j){
        //       for(i = 0; i < img->d_w; ++i){
        //         int y = py[i] - 16, u = pu[i] - 128, v = pv[i] - 128;
        //         rgb[0] = clamp(SCALEYUV(rcoeff(y, u, v)));
        //         rgb[1] = clamp(SCALEYUV(gcoeff(y, u, v)));
        //         rgb[2] = clamp(SCALEYUV(bcoeff(y, u, v)));
        //         rgb += 3;
        //       }
        //       py += img->stride[0];
        //       pu += img->d_w;
        //       pv += img->d_w;
        //     }
        //   }
        // } else {
        // if (1 == 1) {
        //   // If the memory allocations for Lanczos failed (very unlikely!)
        //   // then fall back to cheaper method.
        //   // low quality 1:2 upsampling of u & v by simple pixel doubling.
        //   pu = img->planes[1];
        //   pv = img->planes[2];
        //   rgb = stream->gl_buf;
        //   for(j = 0; j < img->d_h; ++j){
        //     for(i = 0; i < img->d_w; ++i){
        //       // int y = py[i] - 16, u = pu[i/2] - 128, v = pv[i/2] - 128;
        //       int y = py[i] - 16, u = pu[i/2] - 128, v = pv[i/2] - 128;
        //       // rgb[0] = clamp(SCALEYUV(rcoeff(y, u, v)));
        //       // rgb[1] = clamp(SCALEYUV(gcoeff(y, u, v)));
        //       // rgb[2] = clamp(SCALEYUV(bcoeff(y, u, v)));
        //       rgb[0] = clamp(SCALEYUV(rcoeff(y, u, v)));
        //       rgb[1] = clamp(SCALEYUV(gcoeff(y, u, v)));
        //       rgb[2] = clamp(SCALEYUV(bcoeff(y, u, v)));
        //       rgb += 3;
        //     }
        //     py += img->stride[0];
        //     // if(j & 1){
        //       pu += img->stride[1];
        //       pv += img->stride[2];
        //     // }
        //   }
        // }

        // pb->imageMode = plugInModeRGBColor;
        // pb->planeBytes = 1; // planes are interleaved
        // pb->colBytes = pb->planes = 3;
        // pb->loPlane = 0;
        // pb->hiPlane = pb->planes-1;
        // pb->rowBytes = pb->planes*img->d_w;
        // pb->data = out_buf;
        //
        // pb->depth = 8;
        // pb->imageSize.h = pb->theRect.right = img->d_w;
        // pb->imageSize.v = pb->theRect.bottom = img->d_h;
        // pb->theRect.left = pb->theRect.top = 0;

        /*
              // testing code - return single plane
              pb->imageMode = plugInModeGrayScale;
              pb->colBytes = 1;
              pb->planes = 1;
              pb->loPlane = 0;
              pb->hiPlane = 0;
        // Y plane only:
              pb->planeBytes = img->stride[0]*img->d_h;
              pb->rowBytes = img->stride[0];
              pb->data = py;
        // U plane only:
              pb->imageSize.h = pb->theRect.right = img->d_w/2;
              pb->imageSize.v = pb->theRect.bottom = img->d_h/2;
              pb->planeBytes = img->stride[1]*img->d_h/2;
              pb->rowBytes = img->stride[1];
              pb->data = pu;
        */

        return 0;
      }
    }
  }
  return 1;
}



uint8_t stream_get_frame_info(Stream *stream,
                              const uint8_t *gl_rgb_buf, size_t *gl_rgb_buf_size,
                              const uint8_t *gl_luma_buf, size_t *gl_luma_buf_size,
                              const uint8_t *gl_chromaB_buf, size_t *gl_chromaB_buf_size,
                              const uint8_t *gl_chromaR_buf, size_t *gl_chromaR_buf_size,
                              size_t *net_bytes_read) {
  if (stream->gl_rgb_buf && stream->gl_rgb_buf_size > 0 &&
      stream->gl_luma_buf && stream->gl_luma_buf_size > 0 &&
      stream->gl_chromaB_buf && stream->gl_chromaB_buf_size > 0 &&
      stream->gl_chromaR_buf && stream->gl_chromaR_buf_size > 0) {

    gl_rgb_buf = stream->gl_rgb_buf;
    *gl_rgb_buf_size = stream->gl_rgb_buf_size;

    gl_luma_buf = stream->gl_luma_buf;
    *gl_luma_buf_size = stream->gl_luma_buf_size;

    gl_chromaB_buf = stream->gl_chromaB_buf;
    *gl_chromaB_buf_size = stream->gl_chromaB_buf_size;

    gl_chromaR_buf = stream->gl_chromaR_buf;
    *gl_chromaR_buf_size = stream->gl_chromaR_buf_size;

    *net_bytes_read = stream->vpx_frame_size + 12;
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
