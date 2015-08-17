attribute vec3 aVertexPosition;
attribute vec2 aTextureCoord;

uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;

varying lowp vec4 vColor;
varying lowp vec2 vUV;

void main()
{
    vec4 position = uViewMatrix * vec4(aVertexPosition,1.0);

    vColor = vec4(1.0, 1.0, 1.0, 1.0);
    vUV = aTextureCoord;
    gl_Position = uProjectionMatrix * position;
}
