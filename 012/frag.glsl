precision highp float;

#define TIMESTEP 1.0
#define F 0.0545
#define K 0.062
#define Da 0.2
#define Db 0.1

uniform vec2 resolution;
uniform sampler2D tex;
varying vec2 vUV;

void main()
{
  vec2 r = vec2(512.0);
  vec2 p = gl_FragCoord.xy;
  vec2 n = p + vec2(0.0, 1.0);
  vec2 e = p + vec2(1.0, 0.0);
  vec2 s = p + vec2(0.0, -1.0);
  vec2 w = p + vec2(-1.0, 0.0);

  vec2 val = texture2D(tex, vUV).xy;
  vec2 laplacian = texture2D(tex, n / r).xy;
  laplacian += texture2D(tex, e / r).xy;
  laplacian += texture2D(tex, s / r).xy;
  laplacian += texture2D(tex, w / r).xy;
  laplacian -= 4.0 * val;

  vec2 delta;
  delta.x = Da * laplacian.x - val.x * val.y * val.y + F * (1.0 - val.x);
  delta.y = Db * laplacian.y + val.x * val.y * val.y - (K + F) * val.y;

  gl_FragColor = vec4(val + delta * TIMESTEP, 0.0, 0.0);
}
