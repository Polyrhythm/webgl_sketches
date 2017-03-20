precision highp float;

#define COLOR_MIN 0.2
#define COLOR_MAX 0.35

#define saturate(x) clamp(x, 0.0, 1.0)

uniform vec2 resolution;
uniform sampler2D tex;
varying vec2 vUV;

float getGradient(vec2 uv)
{
  return (COLOR_MAX - texture2D(tex, uv).y) /
         (COLOR_MAX - COLOR_MIN);
}

void main()
{
  vec2 eps = vec2(0, 0.002);
  vec2 n = vUV + eps.xy;
  vec2 s = vUV - eps.xy;
  vec2 e = vUV + eps.yx;
  vec2 w = vUV - eps.yx;

  vec3 normal;
  normal.x = getGradient(e) - getGradient(w);
  normal.y = 1.0;
  normal.z = getGradient(n) - getGradient(s);
  normal = normalize(normal);

  float v = getGradient(vUV);

  vec3 lightDir = normalize(vec3(0.5, 1.0, 0.25));
  float incidence = saturate(dot(normal, lightDir));
  vec3 Fd = vec3(0.3, 0.2, 0.7) * incidence;

  gl_FragColor = vec4(Fd, 1.0);
}
