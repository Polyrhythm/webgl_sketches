precision highp float;

uniform float iGlobalTime;
uniform vec2 iResolution;

// ---------------
// noise
// ---------------
const float h1 = 0.3183099;
float hash1(vec3 p) {
  p = 50.0 * fract(p * h1);

  return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float hash1(float n) {
  return fract(n * 17.0 * fract(n * h1));
}

vec4 noised(vec3 x) {
  vec3 p = floor(x);
  vec3 w = fract(x);

  vec3 u = w * w * w * (w * (w * 6.0 - 15.0) + 10.0);
  vec3 du = 30.0 * w * w * (w * (w - 2.0) + 1.0);

  float a = hash1(p + vec3(0.0, 0.0, 0.0));
  float b = hash1(p + vec3(1.0, 0.0, 0.0));
  float c = hash1(p + vec3(0.0, 1.0, 0.0));
  float d = hash1(p + vec3(1.0, 1.0, 0.0));
  float e = hash1(p + vec3(0.0, 0.0, 1.0));
  float f = hash1(p + vec3(1.0, 0.0, 1.0));
  float g = hash1(p + vec3(0.0, 1.0, 1.0));
  float h = hash1(p + vec3(1.0, 1.0, 1.0));

  float k0 =  a;
  float k1 =  b - a;
  float k2 =  c - a;
  float k3 =  e - a;
  float k4 =  a - b - c + d;
  float k5 =  a - c - e + g;
  float k6 =  a - b - e + f;
  float k7 = -a + b + c - d + e - f - g + h;

  return vec4(-1.0 + 2.0 * (k0 + k1 * u.x + k2 * u.y + k3 * u.z + k4 * u.x * u.y + k5 * u.y * u.z + k6 * u.z * u.x + k7 * u.x * u.y * u.z),
                     2.0 * du * vec3(k1 + k4 * u.y + k6 * u.z + k7 * u.y * u.z,
                                     k2 + k5 * u.z + k4 * u.x + k7 * u.z * u.x,
                                     k3 + k6 * u.x + k5 * u.y + k7 * u.x * u.y));
}

const mat3 m3 = mat3(+0.00, +0.80, +0.60,
                     -0.80, +0.36, -0.48,
                     -0.60, -0.48, +0.64);
const mat3 m3i = mat3(+0.00, -0.80, -0.60,
                      +0.80, +0.36, -0.48,
                      +0.60, -0.48, +0.64);

vec4 fbm(vec3 x, int octaves) {
  const float w = 2.0;
  const float s = 0.5;
  float a = 0.0;
  float b = 0.5;
  vec3 d = vec3(0.0);
  mat3 m = mat3(1.0, 0.0, 0.0,
                0.0, 1.0, 0.0,
                0.0, 0.0, 1.0);

  for (int i = 0; i < octaves; i++) {
    vec4 n = noised(x);
    a += b * n.x;
    d += b * m * n.yzw;
    b *= s;
    x = w * m3 * x;
    m = w * m3i * m;
  }

  return vec4(a, d);
}

// ---------------
// Sky
// ---------------
vec3 renderSky(vec3 ro, vec3 rd) {
  const float brightness = 0.9;
  vec3 skyColour = brightness * vec3(0.4, 0.65, 1.0) - rd.y * vec3(0.4, 0.36, 0.4);

  return skyColour;
}

// ---------------
// Setup
// ---------------
mat3 setCamera(in vec3 origin, in vec3 target, float rotation) {
  vec3 forward = normalize(target - origin);
  vec3 orientation = vec3(sin(rotation), cos(rotation), 0.0);
  vec3 left = normalize(cross(forward, orientation));
  vec3 up = normalize(cross(left, forward));
  return mat3(left, up, forward);
}

void main() {
  vec2 p = 1.0 - 2.0 * (gl_FragCoord.xy / iResolution.xy);
  p *= iResolution.xy / iResolution.y;
  vec3 colour = vec3(p.x, p.y, 0.0);

  vec3 origin = vec3(0.0, 1.0, 1.7);
  vec3 target = vec3(0.0);

  mat3 toWorld = setCamera(origin, target, 0.0);
  vec3 rd = toWorld * normalize(vec3(p.xy, 1.25));

  colour = renderSky(origin, rd);

  gl_FragColor = vec4(colour, 1.0);
}
