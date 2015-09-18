window.ZFRONT = {} if not window.ZFRONT

class window.ZFRONT.ZCoderz extends window.Malefic.Stream

  constructor: (zstream) ->
    super('ZCoderz')
    @started = false
    @zstream = zstream
    @zstream.On('data', (buf) =>
      fill = _stream_get_buff_fill(@stream)
      if fill <= 0.8
        @zstream.Play()
      else
        @zstream.Pause()

      @data(buf) if buf
    )

  data: (buf) ->
    if not @started
      @started = true
      @init_stream(buf.subarray(0, 32))
      @write(buf.subarray(32, buf.length))
    else
      @write(buf)

  init_stream: (header) ->
    return console.error("Header length must be 32 bytes") if header.length isnt 32
    @header_buf_ptr = Module._malloc(header.length)
    Module.HEAPU8.set(header, @header_buf_ptr)

    @ptr_byte_size = 4
    @gl_buffer = Module._malloc(1024 * 512 * 3)

    @net_bytes_read_ptr = Module._malloc(@ptr_byte_size)

    # http://stackoverflow.com/questions/2613734/maximum-packet-size-for-a-tcp-connection
    net_packet_size = 1400
    net_buf_size = 32768 * 32 # 10 data ticks
    @stream = _create_stream(@header_buf_ptr, net_packet_size, net_buf_size)
    @tmp = Module._malloc(32768)

  # TODO :: so much mem copy...
  write: (buf) ->
    Module.HEAPU8.set(buf, @tmp)
    status = _stream_write_chunk(@stream, @tmp, buf.length)
    if status isnt 0
      console.error("Error writing to stream")
    # Module._free(clone)

  get_frame: ->
    # timer = new Date()
    # console.log("Start - #{timer.getUTCMilliseconds()}")

    status = _stream_parse(@stream, @gl_buffer, @net_bytes_read_ptr)
    return { success: false, err: "Error parsing stream - #{status}" } if status isnt 0

    gl_buffer = Module.HEAPU8.subarray(@gl_buffer, @gl_buffer + (1024 * 512 * 3))

    net_bytes_read = Module.getValue(@net_bytes_read_ptr, 'i32')
    # console.log("Get Frame Status", status, net_bytes_read)

    # timer = new Date()
    # console.log("End - #{timer.getUTCMilliseconds()}")

    gl_rgb_frame_buf: gl_buffer,
    net_bytes_read: net_bytes_read

  Destroy: ->
    _stream_flush(@stream) if @stream

    Module._free(@stream) if @stream

    Module._free(@header_buf_ptr) if @header_buf_ptr

    Module._free(@gl_rgb_frame_buf) if @gl_frame_buf_ptr

    Module._free(@net_bytes_read_ptr) if @net_bytes_read_ptr
