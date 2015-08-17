window.ZFRONT = {} if not window.ZFRONT

class window.ZFRONT.ZCoderz extends window.Malefic.Stream

  constructor: (zstream) ->
    super('ZCoderz')
    @started = false
    @zstream = zstream
    @zstream.On('data', (buf) =>
      @data(buf)
    )

  data: (buf) ->
    if not @started
      @started = true
      @init_stream(buf.subarray(0, 32))
      @write(buf.subarray(32, buf.length))
    else
      @write(buf)

    frame = @get_frame()
    if not frame.err
      @Trigger('frame', frame)
      # status = _stream_seek(@stream, frame.net_bytes_read)
      # console.error("Failed to seek stream") if not status
    else
      console.log(frame)

  init_stream: (header) ->
    return console.error("Header length must be 32 bytes") if header.length isnt 32
    @header_buf_ptr = Module._malloc(header.length)
    Module.HEAPU8.set(header, @header_buf_ptr)

    @ptr_byte_size = 4
    @gl_rgb_frame_buf_ptr = Module._malloc(@ptr_byte_size)
    @gl_rgb_frame_buf_length_ptr = Module._malloc(@ptr_byte_size)

    @gl_luma_frame_buf_ptr = Module._malloc(@ptr_byte_size)
    @gl_luma_frame_buf_length_ptr = Module._malloc(@ptr_byte_size)

    @gl_chromaB_frame_buf_ptr = Module._malloc(@ptr_byte_size)
    @gl_chromaB_frame_buf_length_ptr = Module._malloc(@ptr_byte_size)

    @gl_chromaR_frame_buf_ptr = Module._malloc(@ptr_byte_size)
    @gl_chromaR_frame_buf_length_ptr = Module._malloc(@ptr_byte_size)

    @net_bytes_read_ptr = Module._malloc(@ptr_byte_size)

    # http://stackoverflow.com/questions/2613734/maximum-packet-size-for-a-tcp-connection
    net_packet_size = 1400
    net_buf_size = 32768 * 4 # 4 data ticks
    @stream = _create_stream(@header_buf_ptr, net_packet_size, net_buf_size)

  # TODO :: so much mem copy...
  write: (buf) ->
    clone = Module._malloc(buf.length)
    Module.HEAPU8.set(buf, clone)
    status = _stream_write_chunk(@stream, clone, buf.length)
    if status isnt 0
      console.error("Error writing to stream")
    Module._free(clone)

  get_frame: ->
    status = _stream_parse(@stream)
    return { success: false, err: "Error parsing stream" } if status isnt 0
    status = _stream_get_frame_info(@stream, @gl_rgb_frame_buf_ptr, @gl_rgb_frame_buf_length_ptr,
                                    @gl_luma_frame_buf_ptr, @gl_luma_frame_buf_length_ptr,
                                    @gl_chromaB_frame_buf_ptr, @gl_chromaB_frame_buf_length_ptr,
                                    @gl_chromaR_frame_buf_ptr, @gl_chromaR_frame_buf_length_ptr,
                                    @net_bytes_read_ptr)
    return { success: false, err: "Error getting stream info" } if status isnt 0

    gl_rgb_frame_buf_length = Module.getValue(@gl_rgb_frame_buf_length_ptr, 'i32')
    gl_rgb_frame_buf = Module.HEAPU8.subarray(@gl_rgb_frame_buf_ptr, @gl_rgb_frame_buf_ptr + gl_rgb_frame_buf_length)

    gl_luma_frame_buf_length = Module.getValue(@gl_luma_frame_buf_length_ptr, 'i32')
    gl_luma_frame_buf = Module.HEAPU8.subarray(@gl_luma_frame_buf_ptr, @gl_luma_frame_buf_ptr + gl_luma_frame_buf_length)

    gl_chromaB_frame_buf_length = Module.getValue(@gl_chromaB_frame_buf_length_ptr, 'i32')
    gl_chromaB_frame_buf = Module.HEAPU8.subarray(@gl_chromaB_frame_buf_ptr, @gl_chromaB_frame_buf_ptr + gl_chromaB_frame_buf_length)

    gl_chromaR_frame_buf_length = Module.getValue(@gl_chromaR_frame_buf_length_ptr, 'i32')
    gl_chromaR_frame_buf = Module.HEAPU8.subarray(@gl_chromaR_frame_buf_ptr, @gl_chromaR_frame_buf_ptr + gl_chromaR_frame_buf_length)

    net_bytes_read = Module.getValue(@net_bytes_read_ptr, 'i32')
    console.log("Get Frame Status", status, net_bytes_read)
    console.log(@gl_rgb_frame_buf_ptr, gl_rgb_frame_buf, gl_rgb_frame_buf_length)
    console.log(@gl_luma_frame_buf_ptr, gl_luma_frame_buf, gl_luma_frame_buf_length)
    console.log(@gl_chromaB_frame_buf_ptr, gl_chromaB_frame_buf, gl_chromaB_frame_buf_length)
    console.log(@gl_chromaR_frame_buf_ptr, gl_chromaR_frame_buf, gl_chromaR_frame_buf_length)

    gl_rgb_frame_buf: gl_rgb_frame_buf,
    gl_luma_frame_buf: gl_luma_frame_buf,
    gl_chromaB_frame_buf: gl_chromaB_frame_buf,
    gl_chromaR_frame_buf: gl_chromaR_frame_buf,
    net_bytes_read: net_bytes_read

  Destroy: ->
    _stream_flush(@stream) if @stream

    Module._free(@stream) if @stream

    Module._free(@header_buf_ptr) if @header_buf_ptr

    Module._free(@gl_rgb_frame_buf_ptr) if @gl_frame_buf_ptr
    Module._free(@gl_rgb_frame_buf_length_ptr) if @gl_frame_buf_length_ptr

    Module._free(@net_bytes_read_ptr) if @net_bytes_read_ptr
