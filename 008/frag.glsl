precision highp float;

#pragma glslify: cnoise2 = require('glsl-noise/classic/2d')

uniform float iGlobalTime;
uniform vec2 iResolution;

#define saturate(x) clamp(x, 0.0, 1.0)
const vec3 SUN_DIR = vec3(0.0, 1.0, 0.0);

// ---------------
// terrain
// ---------------
float terrainMap(vec2 pos) {
  float time = iGlobalTime / 5.0;
  return cnoise2(pos + time);
}

// ---------------
// raytrace
// ---------------
float trace(vec3 ro, vec3 rd) {
  float dist, th;
  const int MAX_STEPS = 400;
  const float minT = 5.0;
  const float maxT = 100.0;
  float t = minT;
  float origT = t;
  float origDist = 0.0;

  for (int i = 0; i < MAX_STEPS; i++) {
    th = 0.001 * t;
    vec3 p = ro + rd * t;
    float env = terrainMap(p.xz);
    dist = p.y - env;
    if (dist < th) {
      break;
    }

    origT = t;
    origDist = dist;
    t += 0.01 * t;

    if (t > maxT) break;
  }

  if (t > maxT) return -1.0;

  return origT + (th - origDist) * (t - origT) / (dist - origDist);
}

vec3 getNormal(const vec3 pos) {
  const float epsilon = 0.02;
  vec3 n = vec3(terrainMap(vec2(pos.x - epsilon, pos.z)) - terrainMap(vec2(pos.x + epsilon, pos.z)),
                2.0 * epsilon,
                terrainMap(vec2(pos.x, pos.z - epsilon)) - terrainMap(vec2(pos.x, pos.z + epsilon)));

  return normalize(n);
}

// ---------------
// render
// ---------------
vec3 renderSky(vec3 ro, vec3 rd) {
  vec3 col = 0.9 * vec3(0.4, 0.65, 1.0) - rd.y * vec3(0.4, 0.36, 0.4);

  return col;
}

vec3 getMaterial(vec3 pos, vec3 n) {
  return vec3(0.2, 0.8, 0.1);
}

float getShading(vec3 pos, vec3 n) {
  return saturate(dot(SUN_DIR, n));
}

vec3 applyFog(vec3 colour, float dist) {
  float fogAmount = 1.0 - exp(-dist * colour.z);
  vec3 fogColour = vec3(0.5, 0.6, 0.7);
  return mix(colour, fogColour, fogAmount);
}

vec3 terrainColour(vec3 ro, vec3 rd, float resT) {
  vec3 pos = ro + rd * resT;
  vec3 n = getNormal(pos);
  float s = getShading(pos, n);
  vec3 m = getMaterial(pos, n);

  return applyFog(m * s, resT);
}

vec3 render(vec3 ro, vec3 rd) {
  vec3 col = vec3(0.0);
  float t = trace(ro, rd);
  if (t != -1.0) {
    col = terrainColour(ro, rd, t);
  } else {
    col = renderSky(ro, rd);
  }

  return col;
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
  vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / iResolution.xy;
  p *= iResolution.xy / iResolution.y;

  vec3 origin = vec3(0.0, 5.0, -17.0);
  vec3 target = vec3(0.0, 0.0, 0.0);
  mat3 toWorld = setCamera(origin, target, 0.0);
  vec3 rd = toWorld * normalize(vec3(p.xy, 1.25));

  vec3 colour = render(origin, rd);

  gl_FragColor = vec4(colour, 1.0);
}
