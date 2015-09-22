window.ZFRONT = {} if not window.ZFRONT

class window.ZFRONT.ZCoderz extends window.Malefic.Stream

  constructor: (zstream, packet_size) ->
    super('ZCoderz')
    @fill = 0
    @packet_size = packet_size
    @started = false
    @zstream = zstream
    @zstream.On('data', (buf) =>
      if @fill <= 0.8
        @zstream.Play()
      else
        @zstream.Pause()

      @data(buf) if buf
    )

  data: (buf) ->
    if not @started
      @started = true
      @init_stream(buf.subarray(0, 32), @packet_size)
      @write(buf.subarray(32, buf.length))
    else
      @write(buf)

  init_stream: (header, packet_size) ->
    return console.error("Header length must be 32 bytes") if header.length isnt 32
    @header_buf_ptr = Module._malloc(header.length)
    Module.HEAPU8.set(header, @header_buf_ptr)

    @ptr_byte_size = 4
    @net_bytes_read_ptr = Module._malloc(@ptr_byte_size)

    # http://stackoverflow.com/questions/2613734/maximum-packet-size-for-a-tcp-connection
    net_packet_size = 1400 # this value drives nothing...
    net_buf_size = packet_size * 10 # 10 data ticks
    @stream = _create_stream(@header_buf_ptr, net_packet_size, net_buf_size)

    @width = _stream_width(@stream)
    @height =_stream_height(@stream)

    @gl_buffer = Module._malloc(@width * @height * 3)
    @gl_luma_buffer = Module._malloc(@width * @height)
    @gl_chromaB_buffer = Module._malloc(@width/2 * @height/2)
    @gl_chromaR_buffer = Module._malloc(@width/2 * @height/2)

    @gl_yuv_stride_ptr = Module._malloc(@ptr_byte_size)

    @tmp = Module._malloc(packet_size)

  write: (buf) ->
    Module.HEAPU8.set(buf, @tmp)
    status = _stream_write_chunk(@stream, @tmp, buf.length)
    if status isnt 0
      console.error("Error writing to stream")

  get_frame: ->
    # timer = new Date()
    # console.log("Start - #{timer.getUTCMilliseconds()}")
    # status = _stream_parse(@stream, @gl_buffer, @net_bytes_read_ptr)
    status = _stream_parse_yuv(@stream, @gl_luma_buffer, @gl_chromaB_buffer, @gl_chromaR_buffer, @net_bytes_read_ptr)
    @fill = _stream_get_buff_fill(@stream)
    return { success: false, err: "Error parsing stream - #{status}" } if status isnt 0
    # gl_buffer = Module.HEAPU8.subarray(@gl_buffer, @gl_buffer + (@width * @height * 3))
    gl_luma_buffer = Module.HEAPU8.subarray(@gl_luma_buffer, @gl_luma_buffer + (@width * @height))
    gl_chromaB_buffer = Module.HEAPU8.subarray(@gl_chromaB_buffer, @gl_chromaB_buffer + (@width/2 * @height/2))
    gl_chromaR_buffer = Module.HEAPU8.subarray(@gl_chromaR_buffer, @gl_chromaR_buffer + (@width/2 * @height/2))

    net_bytes_read = Module.getValue(@net_bytes_read_ptr, 'i32')
    # console.log("Get Frame Status", status, net_bytes_read)

    # timer = new Date()
    # console.log("End - #{timer.getUTCMilliseconds()}")

    # gl_rgb_frame_buf: gl_buffer,
    gl_luma_frame_buf: gl_luma_buffer,
    gl_chromaB_frame_buf: gl_chromaB_buffer,
    gl_chromaR_frame_buf: gl_chromaR_buffer,
    net_bytes_read: net_bytes_read

  Destroy: ->
    _stream_flush(@stream) if @stream

    Module._free(@stream) if @stream

    Module._free(@header_buf_ptr) if @header_buf_ptr

    Module._free(@gl_luma_buffer) if @gl_luma_buffer
    Module._free(@gl_chromaB_buffer) if @gl_chromaB_buffer
    Module._free(@gl_chromaR_buffer) if @gl_chromaR_buffer

    Module._free(@gl_buffer) if @gl_buffer

    Module._free(@net_bytes_read_ptr) if @net_bytes_read_ptr
