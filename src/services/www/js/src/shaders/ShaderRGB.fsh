uniform sampler2D uSampler;

varying lowp vec4 vColor;
varying lowp vec2 vUV;

void main() {
    highp vec4 rgb = texture2D(uSampler, vUV);
    gl_FragColor = vColor * rgb;
}
