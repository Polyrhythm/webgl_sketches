precision highp float;

#define COLOR_MIN 0.2
#define COLOR_MAX 0.4

#define saturate(x) clamp(x, 0.0, 1.0)

uniform vec2 resolution;
uniform sampler2D tex;
varying vec2 vUV;

void main()
{
  float v = (COLOR_MAX - texture2D(tex, vUV).y) /
            (COLOR_MAX - COLOR_MIN);
  gl_FragColor = vec4(v, v, v, 1.0);
}
