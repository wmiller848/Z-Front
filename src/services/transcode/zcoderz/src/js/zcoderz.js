var ZCoderz = function(header) {
  var self = this;
  if (header.length != 32) {
    return console.error("Header length must be 32 bytes")
  }
  self.header_buf = Module._malloc(header.length);
  Module.HEAPU8.set(new Uint8Array(header), self.header_buf);

  self.gl_frame_buf = null;
  self.gl_frame_buf_length = null;

  // http://stackoverflow.com/questions/2613734/maximum-packet-size-for-a-tcp-connection
  var net_packet_size = 1400;
  //
  var gl_buf_size = 1024 * 1024 * 3;
  self.stream = _create_stream(self.header_buf, net_packet_size, gl_buf_size);
  console.log(self.stream);
};

ZCoderz.prototype.write = function(buf) {
  var self = this;
  // Module.ccall('decode', 'undefined', ['number'], [buf]);
  var status = _stream_write_chunk(self.stream, new Uint8Array(buf), buf.length);
  console.log("Write Status", status);
};

ZCoderz.prototype.get_frame = function() {
  var self = this;
  var status = _stream_get_frame(self.stream, self.gl_frame_buf, self.gl_frame_buf_length);
  console.log("Get Frame Status", status, self.gl_frame_buf, self.gl_frame_buf_length);

  return self.gl_frame_buf;
};

ZCoderz.prototype.destroy = function() {
  var self = this;
  _stream_flush(self.stream)
  Module._free(self.stream_buf);
}

// var bytesX = new Uint8Array([0x00, 0x1f, 0x00, 0xff]);
// console.log(bytesX);
// zcoderz.decode(bytesX, 0, 0);
