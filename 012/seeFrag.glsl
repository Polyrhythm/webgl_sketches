precision highp float;

#define COLOR_MIN 0.2
#define COLOR_MAX 0.4

#define saturate(x) clamp(x, 0.0, 1.0)

uniform vec2 resolution;
uniform sampler2D tex;
varying vec2 vUV;

float getGradient(vec2 uv)
{
  return (COLOR_MAX - texture2D(tex, vUV).y) /
         (COLOR_MAX - COLOR_MIN);
}

void main()
{
  vec2 eps = vec2(0, 0.02);
  vec2 n = vUV + eps.xy;
  vec2 s = vUV - eps.xy;
  vec2 e = vUV + eps.yx;
  vec2 w = vUV - eps.yx;
  float v = getGradient(vUV);
  vec3 normal;
  normal.x = getGradient(e) - getGradient(w);
  normal.y = 0.0;
  normal.z = getGradient(n) - getGradient(s);
  normal = normalize(normal);
  gl_FragColor = vec4(normal, 1.0);
}
