window.ZFRONT = {} if not window.ZFRONT

class window.ZFRONT.ZTransportHTTP extends window.Malefic.Core

  constructor: (url) ->
    super('ZTransportHTTP')
    @video = @Ajax(url)
    @video.Status = (status) =>
      @Status(status)
    @video.Then = (err, res) =>
      @Then(err, res)

  Status: (status) ->
    @current_status = status
    @Info(@current_status, null)

  Then: (err, res) ->
    return @Error?(err) if err
    @headers = res.headers()
    @size = new Number(@headers['content-length'])
    @chunk_size = 32768 * 2
    @streamed = 0
    @buf = res.toArray()

    # 26610
    # console.log(@buf.subarray(32, 10000))
    # console.log(@buf.subarray(20000, 30000))

    @Info?(null, @headers)

    @zstream = new ZFRONT.ZStream()
    @zstream.Pause = ->
      @paused = true
    @zstream.Play = ->
      @paused = false
    @zstream.paused = false

    @buffer_time = 400 # ms
    @Open?(@zstream)

    setTimeout( =>
      @Tick()
    , @buffer_time)

  Tick: ->
    if @zstream.paused is false
      chunk_size = @chunk_size
      chunk_size = @buf.length - @streamed if @streamed + chunk_size > @buf.length
      # console.log("Read #{chunk_size} bytes")
      network_bytes = new Uint8Array(@buf.subarray(@streamed, (@streamed + chunk_size)))
      @streamed += network_bytes.length
      # console.log("Streamed #{@streamed} / #{@buf.length}")
      @zstream.Trigger('data', network_bytes)
      return @Close?() if @streamed >= @size
    else if @zstream.paused is true
      @zstream.Trigger('data', null)

    setTimeout( =>
      @Tick()
    , @buffer_time)
