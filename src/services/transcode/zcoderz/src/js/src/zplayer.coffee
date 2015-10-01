window.ZFRONT = {} if not window.ZFRONT

class window.ZFRONT.ZPlayer extends window.Malefic.View

  constructor: (url, context) ->
    super('ZPlayer')

    @zcoderz = null
    @canvas = document.getElementById(context)
    @gl = @canvas.getContext("webgl")
    @gl.viewportWidth = @canvas.width
    @gl.viewportHeight = @canvas.height
    @gl.clearColor(1.0, 1.0, 1.0, 1.0) # Red
    @gl.enable(@gl.DEPTH_TEST) # Enable debth testing

    @luma_texture = @gl.createTexture()
    @chromaB_texture = @gl.createTexture()
    @chromaR_texture = @gl.createTexture()
    # @rgb_texture = @gl.createTexture()

    #
    #
    @buffer_object = {}
    @buffer_object.vertex_position_buffer = @gl.createBuffer()
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @buffer_object.vertex_position_buffer)
    vertices = new Float32Array([
       # x, y, z
      -@gl.viewportWidth, -@gl.viewportHeight,  0.0,
       @gl.viewportWidth, -@gl.viewportHeight,  0.0,
       @gl.viewportWidth,  @gl.viewportHeight,  0.0,
      -@gl.viewportWidth,  @gl.viewportHeight,  0.0
    ])

    @gl.bufferData(@gl.ARRAY_BUFFER, vertices, @gl.STATIC_DRAW)
    @buffer_object.vertex_position_buffer.itemSize = 3
    @buffer_object.vertex_position_buffer.numItems = vertices.length/3

    #
    #
    texture_coords = new Float32Array([
      # u, v
      0.0, 1.0,
      1.0, 1.0,
      1.0, 0.0,
      0.0, 0.0

      # u, v
      # 1.0, 0.0,
      # 0.0, 0.0,
      # 1.0, 1.0,
      # 0.0, 1.0
    ])

    @buffer_object.vertex_texture_buffer = @gl.createBuffer()
    @gl.bindBuffer(@gl.ARRAY_BUFFER, @buffer_object.vertex_texture_buffer)
    @gl.bufferData(@gl.ARRAY_BUFFER, texture_coords, @gl.STATIC_DRAW)
    @buffer_object.vertex_texture_buffer.itemSize = 2
    @buffer_object.vertex_texture_buffer.numItems = texture_coords.length/2

    #
    #
    @buffer_object.vertex_index_buffer = @gl.createBuffer()
    @gl.bindBuffer(@gl.ELEMENT_ARRAY_BUFFER, @buffer_object.vertex_index_buffer)
    vertex_indices = new Uint16Array([
       0, 1, 2,
       0, 2, 3
    ])

    @gl.bufferData(@gl.ELEMENT_ARRAY_BUFFER, vertex_indices, @gl.STATIC_DRAW)
    @buffer_object.vertex_index_buffer.itemSize = 1
    @buffer_object.vertex_index_buffer.numItems = vertex_indices.length/1

    @gl.viewport(0, 0, @gl.viewportWidth, @gl.viewportHeight)
    aspectRatio = @gl.viewportWidth / @gl.viewportHeight

    @mMatrix = mat4.create()
    mat4.identity(@mMatrix)

    @vMatrix = mat4.create()
    mat4.identity(@vMatrix)

    @mvMatrix = mat4.create()
    mat4.identity(@mvMatrix)
    mat4.multiply(@mMatrix, @vMatrix, @mvMatrix)

    @pMatrix = mat4.create()
    mat4.ortho(-@gl.viewportWidth, @gl.viewportWidth, -@gl.viewportHeight, @gl.viewportHeight, -1, 1, @pMatrix)

    # @gl.activeTexture(gl.TEXTURE0)
    # @gl.bindTexture(gl.TEXTURE_2D, textures.tex_y)
    # @gl.uniform1i(shader.uniform.uSamplerY, 0)
    #
    # @gl.activeTexture(gl.TEXTURE1)
    # @gl.bindTexture(gl.TEXTURE_2D, textures.tex_u)
    # @gl.uniform1i(shader.uniform.uSamplerU, 1)
    #
    # @gl.activeTexture(gl.TEXTURE2)
    # @gl.bindTexture(gl.TEXTURE_2D, textures.tex_v)
    # @gl.uniform1i(shader.uniform.uSamplerV, 2)

    # console.log(@pMatrix, @mMatrix, @vMatrix, @mvMatrix)

    shader_protos =
      yuv:
        fsh : null,
        vsh : null,
        src : "shaders/ShaderYUV",
        attribs : ["aVertexPosition", "aTextureCoord"],
        uniforms : ["uViewMatrix", "uProjectionMatrix", "uSamplerY", "uSamplerU", "uSamplerV"]
      rgb:
        fsh : null,
        vsh : null,
        src : "shaders/ShaderRGB",
        attribs : ["aVertexPosition", "aTextureCoord"],
        uniforms : ["uViewMatrix", "uProjectionMatrix", "uSampler"]

    @yuv_shader = new ZFRONT.ZShader(@gl, shader_protos.yuv)
    @yuv_shader.Ready = =>
      console.log("YUV Shader ready")
      console.log(@yuv_shader)
      shader = @yuv_shader.shaderProgram

      @gl.useProgram(shader)
      @gl.activeTexture(@gl.TEXTURE0)
      @gl.bindTexture(@gl.TEXTURE_2D, @luma_texture)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.LINEAR)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.LINEAR)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.CLAMP_TO_EDGE)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.CLAMP_TO_EDGE)

      @gl.activeTexture(@gl.TEXTURE1)
      @gl.bindTexture(@gl.TEXTURE_2D, @chromaB_texture)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.LINEAR)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.LINEAR)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.CLAMP_TO_EDGE)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.CLAMP_TO_EDGE)

      @gl.activeTexture(@gl.TEXTURE2)
      @gl.bindTexture(@gl.TEXTURE_2D, @chromaR_texture)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.LINEAR)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.LINEAR)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.CLAMP_TO_EDGE)
      @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.CLAMP_TO_EDGE)

      # @gl.enable(@gl.DEPTH_TEST)

      @gl.enableVertexAttribArray(shader.attribute.aVertexPosition)
      @gl.bindBuffer(@gl.ARRAY_BUFFER, @buffer_object.vertex_position_buffer)
      @gl.vertexAttribPointer(shader.attribute.aVertexPosition, @buffer_object.vertex_position_buffer.itemSize, @gl.FLOAT, false, 0, 0)

      @gl.enableVertexAttribArray(shader.attribute.aTextureCoord)
      @gl.bindBuffer(@gl.ARRAY_BUFFER, @buffer_object.vertex_texture_buffer)
      @gl.vertexAttribPointer(shader.attribute.aTextureCoord, @buffer_object.vertex_texture_buffer.itemSize, @gl.FLOAT, false, 0, 0)

      @gl.bindBuffer(@gl.ELEMENT_ARRAY_BUFFER, @buffer_object.vertex_index_buffer)
      @gl.uniformMatrix4fv(shader.uniform.uProjectionMatrix, false, @pMatrix)
      @gl.uniformMatrix4fv(shader.uniform.uViewMatrix, false, @mvMatrix)

      @gl.uniform1i(shader.uniform.uSamplerY, 0)
      @gl.uniform1i(shader.uniform.uSamplerU, 1)
      @gl.uniform1i(shader.uniform.uSamplerV, 2)

    # @rgb_shader = new ZFRONT.ZShader(@gl, shader_protos.rgb)
    # @rgb_shader.Ready = =>
    #   console.log("RGB Shader ready")
    #   console.log(@rgb_shader)
    #   shader = @rgb_shader.shaderProgram
    #
    #   @gl.useProgram(shader)
    #   @gl.activeTexture(@gl.TEXTURE0)
    #   @gl.bindTexture(@gl.TEXTURE_2D, @rgb_texture)
    #   # @gl.enable(@gl.DEPTH_TEST)
    #
    #   @gl.enableVertexAttribArray(shader.attribute.aVertexPosition)
    #   @gl.bindBuffer(@gl.ARRAY_BUFFER, @buffer_object.vertex_position_buffer)
    #   @gl.vertexAttribPointer(shader.attribute.aVertexPosition, @buffer_object.vertex_position_buffer.itemSize, @gl.FLOAT, false, 0, 0)
    #
    #   @gl.enableVertexAttribArray(shader.attribute.aTextureCoord)
    #   @gl.bindBuffer(@gl.ARRAY_BUFFER, @buffer_object.vertex_texture_buffer)
    #   @gl.vertexAttribPointer(shader.attribute.aTextureCoord, @buffer_object.vertex_texture_buffer.itemSize, @gl.FLOAT, false, 0, 0)
    #
    #   @gl.bindBuffer(@gl.ELEMENT_ARRAY_BUFFER, @buffer_object.vertex_index_buffer)
    #   @gl.uniformMatrix4fv(shader.uniform.uProjectionMatrix, false, @pMatrix)
    #   @gl.uniformMatrix4fv(shader.uniform.uViewMatrix, false, @mvMatrix)
    #
    #   @gl.uniform1i(shader.uniform.uSampler, 0)

    fps = @Q('#fps_counter')
    zcoders_buf_fill = @Q('#zcoders_buf_fill')
    handler = (time) =>
      fps.innerText = time.realFramesPerSecond
      if @zcoderz and time.framesPerSecond > 15
        zcoders_buf_fill.innerText = @zcoderz.fill
        frame = @zcoderz.get_frame()
        if not frame.err
          @render(frame)
          status = _stream_seek(@zcoderz.stream, frame.net_bytes_read)
          console.error("Failed to seek stream") if status isnt 0

    virtual_fps = 24
    @RenderLoop(handler , virtual_fps)

    transport_promise = new ZFRONT.ZTransportHTTP(url)
    transport_promise.Info = (status, info) ->
      console.log(status, info)
    transport_promise.Open = (zstream) =>
      console.log(url + " opened")
      @zcoderz = new ZFRONT.ZCoderz(zstream, transport_promise.chunk_size)

      console.log("Waiting for frame...")
      @zcoderz.On('frame', (frame) ->
        # console.log("frame", frame)
        # current_frame = frame
      )
    transport_promise.Close = =>
      console.log(url + " closed")
      # @zcoderz.Destroy()

    transport_promise.Error = (err) ->
      console.error(err)

  render: (frame) ->
    @gl.activeTexture(@gl.TEXTURE0)
    @gl.bindTexture(@gl.TEXTURE_2D, @luma_texture)
    @gl.texImage2D(
      @gl.TEXTURE_2D, # target
      0, # mip level
      @gl.LUMINANCE, # internal format
      @zcoderz.width,
      @zcoderz.height,
      0, # border
      @gl.LUMINANCE, #format
      @gl.UNSIGNED_BYTE, # type
      new Uint8Array(frame.gl_luma_frame_buf) # texture data
    )

    @gl.activeTexture(@gl.TEXTURE1)
    @gl.bindTexture(@gl.TEXTURE_2D, @chromaB_texture)
    @gl.texImage2D(
      @gl.TEXTURE_2D, # target
      0, # mip level
      @gl.LUMINANCE, # internal format
      @zcoderz.width/2,
      @zcoderz.height/2,
      0, # border
      @gl.LUMINANCE, #format
      @gl.UNSIGNED_BYTE, # type
      new Uint8Array(frame.gl_chromaB_frame_buf) # texture data
    )

    @gl.activeTexture(@gl.TEXTURE2)
    @gl.bindTexture(@gl.TEXTURE_2D, @chromaR_texture)
    @gl.texImage2D(
      @gl.TEXTURE_2D, # target
      0, # mip level
      @gl.LUMINANCE, # internal format
      @zcoderz.width/2,
      @zcoderz.height/2,
      0, # border
      @gl.LUMINANCE, #format
      @gl.UNSIGNED_BYTE, # type
      new Uint8Array(frame.gl_chromaR_frame_buf) # texture data
    )

    # @gl.texImage2D(
    #   @gl.TEXTURE_2D, # target
    #   0, # mip level
    #   @gl.RGB, # internal format
    #   @zcoderz.width,
    #   @zcoderz.height,
    #   0, # border
    #   @gl.RGB, #format
    #   @gl.UNSIGNED_BYTE, # type
    #   frame.gl_rgb_frame_buf # texture data
    # )

    # Non po2
    # @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.LINEAR)
    # @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_S, @gl.CLAMP_TO_EDGE)
    # @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_WRAP_T, @gl.CLAMP_TO_EDGE)

    # @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MAG_FILTER, @gl.LINEAR)
    # @gl.texParameteri(@gl.TEXTURE_2D, @gl.TEXTURE_MIN_FILTER, @gl.LINEAR_MIPMAP_NEAREST)
    # @gl.generateMipmap(@gl.TEXTURE_2D)

    @gl.clear(@gl.COLOR_BUFFER_BIT | @gl.DEPTH_BUFFER_BIT)
    @gl.drawElements(@gl.TRIANGLES, @buffer_object.vertex_index_buffer.numItems, @gl.UNSIGNED_SHORT, 0)
