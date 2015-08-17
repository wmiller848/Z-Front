uniform sampler2D uSampler;

varying lowp vec4 vColor;
varying lowp vec2 vUV;

void main()
{
    // vec4 tex = texture2D(uSampler, vUV);
    // float R = tex.r / 255.0;
    // float G = tex.g / 255.0;
    // float B = tex.b / 255.0;
    // R = (R<0.0?0.0:(R>255.0?255.0:R));
    // G = (G<0.0?0.0:(G>255.0?255.0:G));
    // B = (B<0.0?0.0:(B>255.0?255.0:B));
    // gl_FragColor = vColor * texture2D(uSampler, vUV);

    highp vec4 yuv = texture2D(uSampler, vUV);
    gl_FragColor = vColor * yuv;

    // //
    // highp float c = yuv.r - 16.0;
    // highp float d = yuv.g - 128.0;
    // highp float e = yuv.b - 128.0;
    // highp vec4 vRGB = vec4(c, d, e, 1.0);

    //
    // highp float r = (298.0 * c             + 409.0 * e + 128.0);
    // highp float g = (298.0 * c - 100.0 * d - 208.0 * e + 128.0);
    // highp float b = (298.0 * c + 516.0 * d             + 128.0);
    //
    // //
    // // highp vec4 vRGB = vec4(r, g, b, 1.0);
    // highp vec4 vRGB = vec4(r / 256.0, g / 256.0, b / 256.0, 1.0);

    // gl_FragColor = vColor * vRGB;
}
