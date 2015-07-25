window.ZFRONT = {} if not window.ZFRONT

class window.ZFRONT.ZShader extends window.Malefic.Core

  constructor: (gl, shader_proto)->
    super('ZShader')

    @shader = {}
    
    @fsh_loaded = false
    @shader_fsh_source = @Ajax(shader_proto.src + '.fsh')
    @shader_fsh_source.Status = (status) =>
      @Status(status)
    @shader_fsh_source.Then = (err, res) =>
      @Then(gl, err, res, 'FRAGMENT_SHADER')
      @fsh_loaded = true
      @compile(gl, shader_proto)

    @vsh_loaded = false
    @shader_vsh_source = @Ajax(shader_proto.src + '.vsh')
    @shader_vsh_source.Status = (status) =>
      @Status(status)
    @shader_vsh_source.Then = (err, res) =>
      @Then(gl, err, res, 'VERTEX_SHADER')
      @vsh_loaded = true
      @compile(gl, shader_proto)

  Status: (status) ->
    console.log(status)

  Then: (gl, err, res, type) ->
    shader = gl.createShader(gl[type])
    gl.shaderSource(shader, res.toString())
    gl.compileShader(shader)
    unless gl.getShaderParameter(shader, gl.COMPILE_STATUS)
      return console.log(gl.getShaderInfoLog(shader))
    @shader[type] = shader

  compile: (gl, shader_proto) ->
    return unless @vsh_loaded and @fsh_loaded
    shaderProgram = gl.createProgram()
    gl.attachShader(shaderProgram, @shader.FRAGMENT_SHADER)
    gl.attachShader(shaderProgram, @shader.VERTEX_SHADER)
    gl.linkProgram(shaderProgram)
    unless gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)
      return console.log("Could not initialise shaders")

    gl.useProgram(shaderProgram)

    # Add any shader attributes and uniforms that we specified needing
    attribs = shader_proto.attribs
    if attribs
      shaderProgram.attribute = {}
      for i in attribs
        attrib = attribs[i]
        shaderProgram.attribute[attrib] = gl.getAttribLocation(shaderProgram, attrib)
        if shaderProgram.attribute[attrib] != -1
          console.log("Shader added attribute: " + attrib)
          console.log("Attribute location " + shaderProgram.attribute[attrib])
        else
          console.log("Attribute " + attrib + " not found")

    uniforms = shaderProto.uniforms
    if uniforms
      shaderProgram.uniform = {}
      for i in uniforms
        uniform = uniforms[i]
        shaderProgram.uniform[uniform] = gl.getUniformLocation(shaderProgram, uniform)
        if shaderProgram.uniform[uniform] != -1)
          console.log("Shader added uniform: " + uniform)
          console.log("Uniform location " + shaderProgram.uniform[uniform])
        else
          console.log("Uniform " + uniform + " not found")

    @shaderProgram = shaderProgram
    @Ready?()

# function initShader(gl, scene, shaderName) {
# getShader(gl, scene, shaderName, "fsh");
# getShader(gl, scene, shaderName, "vsh");
# };
#
# function getShader(gl, scene, shaderName, type)
# {
# var shader;
# var self = this;
# if (type == "fsh")
# {
# shader = gl.createShader(gl.FRAGMENT_SHADER);
# // Web Based async load
# if ($ != null)
# {
# $.get(shaderName + '.fsh', function(source)
# {
# gl.shaderSource(shader, source);
# gl.compileShader(shader);
# if (!gl.getShaderParameter(shader,gl.COMPILE_STATUS))
# {
# console.log(gl.getShaderInfoLog(shader));
# alert(gl.getShaderInfoLog(shader));
# }
# else
# {
# var shaderProperties =
# {
# name: shaderName,
# assetType: "shader",
# type: type
# };
# shader.properties = shaderProperties;
# scene.assetLoaded(shader, shaderProperties);
# }
# });
# }
# // iOS-v8 gl
# else
# {
# var source = get(shaderName, type, "local");
# gl.shaderSource(shader, source);
# gl.compileShader(shader);
# if (!gl.getShaderParameter(shader,gl.COMPILE_STATUS))
# {
# log("Error compiling shader");
# // TODO: Bind GL_Log
# //console.log(gl.getShaderInfoLog(shader));
# //alert(gl.getShaderInfoLog(shader));
# }
# else
# {
# //scene.log("fsh Shader Compiled");
# var shaderProperties =
# {
# name: shaderName,
# assetType: "shader",
# type: type
# };
# shader.properties = shaderProperties;
# scene.assetLoaded(shader);
# }
#
# }
# }
# else if (type == "vsh")
# {
# shader = gl.createShader(gl.VERTEX_SHADER);
# // Web Based async load
# if($ != null)
# {
# $.get(shaderName + '.vsh', function(source)
# {
# gl.shaderSource(shader, source);
# gl.compileShader(shader);
# if (!gl.getShaderParameter(shader,gl.COMPILE_STATUS))
# {
# console.log(gl.getShaderInfoLog(shader));
# alert(gl.getShaderInfoLog(shader));
# }
# var shaderProperties =
# {
# name: shaderName,
# assetType: "shader",
# type: type
# };
# shader.properties = shaderProperties;
# scene.assetLoaded(shader);
# });
# }
# // iOS-v8 gl
# else
# {
# var source = get(shaderName, type, "local");
# gl.shaderSource(shader, source);
# gl.compileShader(shader);
# if (!gl.getShaderParameter(shader,gl.COMPILE_STATUS))
# {
# log("Error compiling shader");
# // TODO: Bind GL_Log
# //console.log(gl.getShaderInfoLog(shader));
# //alert(gl.getShaderInfoLog(shader));
# }
# else
# {
# //scene.log("vsh Shader Compiled");
# var shaderProperties =
# {
# name: shaderName,
# assetType: "shader",
# type: type
# };
# shader.properties = shaderProperties;
# scene.assetLoaded(shader);
# }
# }
# }
# };
#
# function compileShader(gl, shaderProto)
# {
# log("Shader loading: " + shaderProto.name);
# var shaderProgram = gl.createProgram();
# gl.attachShader(shaderProgram, shaderProto.fsh);
# gl.attachShader(shaderProgram, shaderProto.vsh);
# gl.linkProgram(shaderProgram);
# if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS))
# {
# //alert("Could not initialise shaders");
# log("Could not initialise shaders");
# }
#
# gl.useProgram(shaderProgram);
#
# // Add any shader attributes and uniforms that we specified needing
# var attribs = shaderProto.attribs;
# if(attribs)
# {
# shaderProgram.attribute = {};
# for(var i in attribs) {
# var attrib = attribs[i];
# shaderProgram.attribute[attrib] = gl.getAttribLocation(shaderProgram, attrib);
# if(shaderProgram.attribute[attrib] != -1)
# {
# log("Shader added attribute: " + attrib);
# //log("Attribute location " + shaderProgram.attribute[attrib]);
# }
# else
# {
# log("Attribute " + attrib + " not found");
# }
#
# }
# }
# var uniforms = shaderProto.uniforms;
# if(uniforms)
# {
# shaderProgram.uniform = {};
# for(var i in uniforms)
# {
# var uniform = uniforms[i];
# shaderProgram.uniform[uniform] = gl.getUniformLocation(shaderProgram, uniform);
# if(shaderProgram.uniform[uniform] != -1)
# {
# log("Shader added uniform: " + uniform);
# //log("Uniform location " + shaderProgram.uniform[uniform]);
# }
# else
# {
# log("Uniform " + uniform + " not found");
# }
# }
# }
# if(shaderProgram)
# {
# log("Shader loaded: " + shaderProto.name);
# return shaderProgram;
# }
# else
# {
# return null;
# }
# }
