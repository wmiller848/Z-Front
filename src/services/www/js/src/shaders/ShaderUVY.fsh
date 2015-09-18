uniform sampler2D uSamplerY;
uniform sampler2D uSamplerU;
uniform sampler2D uSamplerV;

varying highp vec2 vUV;

void main() {
    highp float y = texture2D(uSamplerY, vUV).r;
    highp float u = texture2D(uSamplerU, vUV).r;
    highp float v = texture2D(uSamplerV, vUV).r;

    highp float r = y + 1.13983/256.0 * (v - 128.0/256.0);
    highp float g = y - 0.39465/256.0 * (u - 128.0/256.0) - 0.58060/256.0* (v - 128.0/256.0);
    highp float b = y + 2.03211/256.0 * (u - 128.0/256.0);

    // gl_FragColor = vec4(y,u,v,1.0);
    // highp float r = y +             1.402 * v;
    // highp float g = y - 0.344 * u - 0.714 * v;
    // highp float b = y + 1.772 * u;

    gl_FragColor = vec4(r,g,b,1.0);
}
