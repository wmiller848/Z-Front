var ZCoderz = function(header) {
  var self = this;
  if (header.length != 32) {
    return console.error("Header length must be 32 bytes")
  }
  self.header_buf_ptr = Module._malloc(header.length);
  Module.HEAPU8.set(header, self.header_buf_ptr);

  var ptr_size = 4;
  self.gl_frame_buf_ptr = Module._malloc(ptr_size);
  self.gl_frame_buf_length_ptr = Module._malloc(ptr_size);
  self.net_bytes_read_ptr = Module._malloc(ptr_size);

  // http://stackoverflow.com/questions/2613734/maximum-packet-size-for-a-tcp-connection
  var net_packet_size = 1400;
  var net_buf_size = 65536; // 2 ^ 16
  //
  var gl_buf_size = 1024 * 1024 * 3;
  self.stream = _create_stream(self.header_buf_ptr, net_packet_size, net_buf_size, gl_buf_size);
  console.log(self.stream);
};

ZCoderz.prototype.write = function(buf) {
  var self = this;
  // Module.ccall('decode', 'undefined', ['number'], [buf]);
  // var clone = new Uint8Array(buf);
  // console.log(clone);
  var clone_length = buf.length;
  var clone = Module._malloc(clone_length);
  Module.HEAPU8.set(buf, clone);
  var status = _stream_write_chunk(self.stream, clone, clone_length);
  Module._free(clone);
  console.log("Write Status", status);
};

ZCoderz.prototype.get_frame = function() {
  var self = this;
  if(_stream_parse(self.stream)) {
    console.log("Error parsing stream");
    return;
  }
  var status = _stream_get_frame_info(self.stream, self.gl_frame_buf_ptr, self.gl_frame_buf_length_ptr, self.net_bytes_read_ptr);

  var gl_frame_buf_length = Module.getValue(self.gl_frame_buf_length_ptr, 'i32');
  var gl_frame_buf = Module.HEAPU8.subarray(self.gl_frame_buf_ptr, self.gl_frame_buf_ptr + gl_frame_buf_length);
  var net_bytes_read = Module.getValue(self.net_bytes_read_ptr, 'i32');
  console.log("Get Frame Status", status, gl_frame_buf, gl_frame_buf_length, net_bytes_read);

  return self.gl_frame_buf;
};

ZCoderz.prototype.destroy = function() {
  var self = this;
  if (self.stream)
    _stream_flush(self.stream);

  if (self.header_buf)
    Module._free(self.header_buf_ptr);

  if (self.gl_frame_buf_ptr)
    Module._free(self.gl_frame_buf_ptr);

  if (self.gl_frame_buf_length_ptr)
    Module._free(self.gl_frame_buf_length_ptr);

  if (self.net_bytes_read_ptr)
    Module._free(self.net_bytes_read_ptr);
}

// var bytesX = new Uint8Array([0x00, 0x1f, 0x00, 0xff]);
// console.log(bytesX);
// zcoderz.decode(bytesX, 0, 0);
