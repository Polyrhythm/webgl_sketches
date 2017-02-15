precision highp float;

#pragma glslify: snoise2 = require('glsl-noise/simplex/2d')
#pragma glslify: snoise3 = require('glsl-noise/simplex/3d')

uniform float iGlobalTime;
uniform vec2 iResolution;

#define saturate(x) clamp(x, 0.0, 1.0)
const vec3 SUN_DIR = vec3(0.0, 1.0, 0.0);

// ---------------
// terrain
// ---------------
float terrainMap(vec2 pos) {
  float scale = 0.01;
  const float amplitude = 13.0;
  pos *= scale;
  float time = iGlobalTime / 5.0;
  return snoise2(pos + time * 0.1) * amplitude;
}

// ---------------
// raytrace
// ---------------
vec2 trace(vec3 ro, vec3 rd) {
  float dist, th;
  const int MAX_STEPS = 400;
  const float minT = 5.0;
  const float maxT = 300.0;
  float t = minT;
  float origT = t;
  float origDist = 0.0;
  float height = 0.0;

  for (int i = 0; i < MAX_STEPS; i++) {
    th = 0.001 * t;
    vec3 p = ro + rd * t;
    float env = terrainMap(p.xz);
    dist = p.y - env;
    height = p.y;
    if (dist < th) {
      break;
    }

    origT = t;
    origDist = dist;
    t += 0.01 * t * dist * 0.6;

    if (t > maxT) break;
  }

  if (t > maxT) return vec2(-1.0);

  t = origT + (th - origDist) * (t - origT) / (dist - origDist);

  return vec2(t, height);
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
  vec3 col = 0.9 * vec3(0.8, 0.9, 1.0) - rd.y * vec3(0.75, 0.36, 0.4);

  return col;
}

vec3 getMaterial(vec3 pos, vec3 n) {
  return vec3(0.2, 0.8, 0.1);
}

float getShading(vec3 pos, vec3 n, float height) {
  return saturate(dot(SUN_DIR, n)) + height * 0.055;
}

vec3 applyFog(vec3 colour, float dist) {
  float fogAmount = 1.0 - exp(-dist * colour.z * 0.1);
  vec3 fogColour = vec3(0.5, 0.6, 0.7);
  return mix(colour, fogColour, fogAmount);
}

void doBumpMap(const vec3 pos, const vec3 n) {
}

vec3 terrainColour(vec3 ro, vec3 rd, vec2 env) {
  vec3 pos = ro + rd * env.x;

  vec3 n = getNormal(pos);
  // bump map
  doBumpMap(pos, n);

  float s = getShading(pos, n, env.y);
  vec3 m = getMaterial(pos, n);

  return applyFog(m * s, env.x);
}

vec3 render(vec3 ro, vec3 rd) {
  vec3 col = vec3(0.0);
  vec2 env = trace(ro, rd);
  if (env.x != -1.0) {
    col = terrainColour(ro, rd, env);
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

  vec3 origin = vec3(0.0, 20.0, -40.0);
  vec3 target = vec3(0.0, 0.0, 0.0);
  mat3 toWorld = setCamera(origin, target, 0.0);
  vec3 rd = toWorld * normalize(vec3(p.xy, 1.25));

  vec3 colour = render(origin, rd);

  gl_FragColor = vec4(colour, 1.0);
}
