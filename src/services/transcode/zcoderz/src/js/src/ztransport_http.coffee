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
    @chunk_size = 32768
    @streamed = 0
    @buf = res.toArray()

    @Info?(null, @headers)

    @zstream = new ZFRONT.ZStream()
    @buffer_time = 50 # ms
    @Open?(@zstream)
    # setInterval( (time) =>
    #   @Tick(time)
    # , @buffer_time)

    setTimeout( (time) =>
      @Tick(time)
    , @buffer_time)

    setTimeout( (time) =>
      @Tick(time)
    , @buffer_time * 2)

    setTimeout( (time) =>
      @Tick(time)
    , @buffer_time * 3)

  Tick: (time) ->
    chunk_size = @chunk_size
    chunk_size = @buf.length - @streamed if @streamed + chunk_size > @buf.length
    console.log(chunk_size)
    network_bytes = new Uint8Array(@buf.subarray(@streamed, (@streamed + chunk_size)))
    @streamed += network_bytes.length
    @zstream.Trigger('data', network_bytes)
    @Close?() if @streamed >= @size
