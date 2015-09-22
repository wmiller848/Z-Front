uniform sampler2D uSamplerY;
uniform sampler2D uSamplerU;
uniform sampler2D uSamplerV;

varying highp vec2 vUV;

// void main() {
//     highp float y = texture2D(uSamplerY, vUV).r;
//     highp float u = texture2D(uSamplerU, vUV).r;
//     highp float v = texture2D(uSamplerV, vUV).r;
//
//     highp float r = y + 1.13983/256.0 * (v - 128.0/256.0);
//     highp float g = y - 0.39465/256.0 * (u - 128.0/256.0) - 0.58060/256.0* (v - 128.0/256.0);
//     highp float b = y + 2.03211/256.0 * (u - 128.0/256.0);
//
//     // gl_FragColor = vec4(y,u,v,1.0);
//     // highp float r = y +             1.402 * v;
//     // highp float g = y - 0.344 * u - 0.714 * v;
//     // highp float b = y + 1.772 * u;
//
//     gl_FragColor = vec4(r,g,b,1.0);
// }

// const highp vec3 R_cf = vec3(1.164383,  0.000000,  1.596027);
// const highp vec3 G_cf = vec3(1.164383, -0.391762, -0.812968);
// const highp vec3 B_cf = vec3(1.164383,  2.017232,  0.000000);
// const highp vec3 offset = vec3(-0.0625, -0.5, -0.5);
//
// void main() {
//   highp float y = texture2D(uSamplerY, vUV).r;
//   highp float u = texture2D(uSamplerU, vUV).r;
//   highp float v = texture2D(uSamplerV, vUV).r;
//   highp vec3 yuv = vec3(y, u, v);
//   yuv += offset;
//   gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
//   gl_FragColor.r = dot(yuv, R_cf);
//   gl_FragColor.g = dot(yuv, G_cf);
//   gl_FragColor.b = dot(yuv, B_cf);
// }

const highp mat4 YUV2RGB = mat4(
  1.1643828125, 0.0, 1.59602734375, -0.87078515625,
  1.1643828125, -0.39176171875, -0.81296875, 0.52959375,
  1.1643828125, 2.017234375, 0.0, -1.081390625,
  0.0, 0.0, 0.0, 1.0
);

void main(void) {
  highp float y = texture2D(uSamplerY, vUV).r;
  highp float u = texture2D(uSamplerU, vUV).r;
  highp float v = texture2D(uSamplerV, vUV).r;
  gl_FragColor = vec4(y, u, v, 1) * YUV2RGB;
}
