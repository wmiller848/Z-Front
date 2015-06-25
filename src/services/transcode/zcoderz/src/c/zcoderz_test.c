//
//
#include <stdio.h>

#include <vpx/vpx_decoder.h>

#include <tools_common.h>
#include <video_stream_reader.h>

#include <zcoderz.h>

void test_stream_write() {
  // stream = create_stream(header);
  //
  // stream_write(stream, buf, buf_size);
  //
  // destroy_stream(stream);
}

void test_stream_write_chunk() {
  // stream = create_stream(header);
  //
  // stream_write_chunk(stream, buf, buf_size);
  //
  // destroy_stream(stream);
}

void test_stream_get_frame() {
  // Stream *stream = create_stream(header);
  //
  // stream_write(stream, buf, buf_size);
  // uint8_t *frame = (uint8_t*)malloc(sizeof(uint8_t) * 512);
  // uint8_t *frame_size;
  // *frame_size = 0;
  // stream_get_frame(stream, buf, buf_size, frame);
  //
  // assert(*frame_size != 0);
  //
  // destroy_stream(stream);
  // free(frame);
}

int main(int argc, char const *argv[]) {
  version();
  test_stream_write();
  test_stream_write_chunk();
  test_stream_get_frame();
  return 0;
}
