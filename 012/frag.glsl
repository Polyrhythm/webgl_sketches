precision highp float;

uniform vec2 resolution;
uniform sampler2D tex;
varying vec2 vUV;

// Simulation type
#define WAVES

#define TIMESTEP 1.0

#ifdef DEFAULT
#define F 0.0545
#define K 0.062
#define Da 1.0
#define Db 0.5
#endif

#ifdef MITOSIS
#define F 0.0367
#define K 0.0649
#define Da 1.0
#define Db 0.5
#endif

#ifdef DOTS
#define F 0.0321
#define K 0.0559
#define Da 1.0
#define Db 0.5
#endif

#ifdef JITTER
#define F 0.04
#define K 0.062
#define Da 1.0
#define Db 0.55
#endif

#ifdef ASYMMETRIC_MITOSIS
#define F mix(0.035, 0.07, vUV.x)
#define K 0.0649
#define Da 1.0
#define Db 0.5
#endif

#ifdef WAVES
#define F 0.0585 * vUV.y * vUV.y * 0.01
#define K mix(0.01, 0.03, vUV.x) * vUV.x
#define Da 1.0
#define Db 0.5
#endif

void main()
{
  vec2 r = resolution;
  vec2 p = gl_FragCoord.xy;
  vec2 n = p + vec2(0.0, 1.0);
  vec2 ne = p + vec2(1.0, 1.0);
  vec2 nw = p + vec2(-1.0, 1.0);
  vec2 e = p + vec2(1.0, 0.0);
  vec2 s = p + vec2(0.0, -1.0);
  vec2 se = p + vec2(1.0, -1.0);
  vec2 sw = p + vec2(-1.0, -1.0);
  vec2 w = p + vec2(-1.0, 0.0);

  vec2 val = texture2D(tex, vUV).xy;
  vec2 laplacian = texture2D(tex, n / r).xy * 0.2;
  laplacian += texture2D(tex, e / r).xy * 0.2;
  laplacian += texture2D(tex, s / r).xy * 0.2;
  laplacian += texture2D(tex, w / r).xy * 0.2;
  laplacian += texture2D(tex, nw / r).xy * 0.05;
  laplacian += texture2D(tex, ne / r).xy * 0.05;
  laplacian += texture2D(tex, sw / r).xy * 0.05;
  laplacian += texture2D(tex, se / r).xy * 0.05;
  laplacian += -1.0 * val;

  vec2 delta;
  delta.x = Da * laplacian.x - val.x * val.y * val.y + F * (1.0 - val.x);
  delta.y = Db * laplacian.y + val.x * val.y * val.y - (K + F) * val.y;

  gl_FragColor = vec4(val + delta * TIMESTEP, 0.0, 0.0);
}
