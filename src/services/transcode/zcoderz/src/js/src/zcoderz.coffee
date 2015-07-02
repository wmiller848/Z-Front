window.ZFRONT = {} if not window.ZFRONT

class window.ZFRONT.ZCoderz extends window.Malefic.Core

constructor: (header) ->
  return console.error("Header length must be 32 bytes") if header.length isnt 32

  @header_buf_ptr = Module._malloc(header.length)
  Module.HEAPU8.set(header, @header_buf_ptr)

  @ptr_byte_size = 4
  @gl_frame_buf_ptr = Module._malloc(@ptr_byte_size)
  @gl_frame_buf_length_ptr = Module._malloc(@ptr_byte_size)
  @net_bytes_read_ptr = Module._malloc(@ptr_byte_size)

  # http://stackoverflow.com/questions/2613734/maximum-packet-size-for-a-tcp-connection
  net_packet_size = 1400
  net_buf_size = 65536 # 2 ^ 16
  # Size of the total buffer
  @gl_buf_size = 1024 * 1024 * 3
  self.stream = _create_stream(@header_buf_ptr, net_packet_size, net_buf_size, gl_buf_size)
  console.log(self.stream)

write: (buf) ->
  clone_length = buf.length
  clone = Module._malloc(clone_length)
  Module.HEAPU8.set(buf, clone)
  status = _stream_write_chunk(self.stream, clone, clone_length)
  Module._free(clone)
  console.log("Write Status", status)

  true

get_frame: ->
  return console.log("Error parsing stream") if _stream_parse(self.stream)
  status = _stream_get_frame_info(@stream, @gl_frame_buf_ptr, @gl_frame_buf_length_ptr, @net_bytes_read_ptr)
  return console.log("Error getting stream info") unless status

  gl_frame_buf_length = Module.getValue(@gl_frame_buf_length_ptr, 'i32')
  gl_frame_buf = Module.HEAPU8.subarray(@gl_frame_buf_ptr, @gl_frame_buf_ptr + gl_frame_buf_length)
  net_bytes_read = Module.getValue(@net_bytes_read_ptr, 'i32')
  console.log("Get Frame Status", status, @gl_frame_buf_ptr, gl_frame_buf, gl_frame_buf_length, net_bytes_read)

  gl_frame_buf

destroy: ->
  _stream_flush(@stream) if @stream

  Module._free(@header_buf_ptr) if @header_buf

  Module._free(@gl_frame_buf_ptr) if @gl_frame_buf_ptr

  Module._free(@gl_frame_buf_length_ptr) if @gl_frame_buf_length_ptr

  Module._free(@net_bytes_read_ptr) if @net_bytes_read_ptr

  true
