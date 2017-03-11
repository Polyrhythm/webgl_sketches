precision highp float;

#pragma glslify: snoise2 = require('glsl-noise/simplex/2d')
#pragma glslify: snoise3 = require('glsl-noise/simplex/3d')

uniform float iGlobalTime;
uniform vec2 iResolution;

#define saturate(x) clamp(x, 0.0, 1.0)
#define PI 3.14159265359
const vec3 SUN_DIR = normalize(vec3(0.2, 1.0, -0.75));

// ---------------
// transformations
// ---------------
float degToRad(float deg) {
  return deg * (PI / 180.0);
}

mat3 rotateY(float deg) {
  float theta = degToRad(deg);
  float sinTh = sin(theta);
  float cosTh = cos(theta);
  return mat3(cosTh, 0.0, sinTh,
              0.0,   1.0, 0.0,
             -sinTh, 0.0, cosTh);
}

mat3 scale(vec3 s) {
  return mat3(s.x, 0.0, 0.0,
              0.0, s.y, 0.0,
              0.0, 0.0, s.z);
}

// ---------------
// bird
// ---------------
const float BIRD_MAT = 1.0;
float sdSphere(vec3 p, float r) {
  float f = pow(dot(p.xx, p.xx), mix(1.1, 1.16, sin(iGlobalTime) * 0.5 + 1.0));
  p -= 0.03 * f;
  return length(p) - r;
}

vec2 birdMap(vec3 pos) {
  vec3 offset = vec3(4.0, -10.0, 28.0);
  vec3 movement = vec3(iGlobalTime, sin(iGlobalTime), iGlobalTime * 1.5 + cos(iGlobalTime * 0.5) * 1.5);
  vec3 basePos = pos + offset - movement;
  mat3 rot = rotateY(-35.0);
  vec2 torso = vec2(sdSphere(rot * basePos, 3.0), BIRD_MAT);

  return torso;
}

vec3 birdNormal(vec3 p) {
  vec2 eps = vec2(0.0, 0.002);
  vec3 n;

  n.x = birdMap(p + eps.yxx).x - birdMap(p - eps.yxx).x;
  n.y = birdMap(p + eps.xyx).x - birdMap(p - eps.xyx).x;
  n.z = birdMap(p + eps.xxy).x - birdMap(p - eps.xxy).x;

  return normalize(n);
}

vec2 birdTrace(vec3 ro, vec3 rd, out float resT) {
  const int MAX_STEPS = 64;
  const float EPSILON = 0.002;
  const float MAX_DIST = 50.0;
  float t = 0.0;
  for (int i = 0; i < MAX_STEPS; i++) {
    vec2 d = birdMap(ro + rd * t);

    if (d.x < EPSILON) {
      resT = t;
      return d;
    }

    if (t > MAX_DIST) {
      return vec2(-1.0);
    }

    t += d.x;
  }

  return vec2(-1.0);
}

vec4 renderBird(vec3 ro, vec3 rd) {
  vec4 col = vec4(0.0);

  float dist;
  vec2 bird = birdTrace(ro, rd, dist);
  if (bird.x == -1.0) {
    return col;
  }

  vec3 pos = ro + rd * dist;
  vec3 n = birdNormal(pos);
  vec3 diffuseC = vec3(sin(iGlobalTime) * 0.1 + 1.0, 0.4, 0.6);

  col = vec4(diffuseC * saturate(dot(n, SUN_DIR)), 1.0);

  return col;
}

// ---------------
// terrain
// ---------------
float terrainMap(vec2 pos) {
  float scale = 0.01;
  const float amplitude = 13.0;
  pos *= scale;
  float time = iGlobalTime / 5.0;
  return snoise2(pos) * amplitude;
}

// ---------------
// raytrace
// ---------------
vec2 trace(vec3 ro, vec3 rd) {
  float dist, th;
  const int MAX_STEPS = 400;
  const float minT = 5.0;
  const float maxT = 400.0;
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
  vec3 green = vec3(0.2, 0.8, 0.1);
  vec3 brown = vec3(0.9, 0.8, 0.3);

  return 0.65 * mix(brown, green, smoothstep(0.4, 0.9, n.y));
}

float getShading(vec3 pos, vec3 n, float height) {
  return saturate(dot(SUN_DIR, n)) + height * 0.035;
}

vec3 applyFog(vec3 colour, float dist) {
  float fogAmount = 1.0 - exp(-dist * colour.z * 0.1);
  vec3 fogColour = vec3(0.5, 0.6, 0.7) * 0.8;
  return mix(colour, fogColour, fogAmount);
}

vec3 terrainColour(vec3 ro, vec3 rd, vec2 env) {
  vec3 pos = ro + rd * env.x;

  vec3 n = getNormal(pos);
  float s = getShading(pos, n, env.y);
  vec3 m = getMaterial(pos, n);

  return applyFog(m * s, env.x);
}

vec4 render(vec3 ro, vec3 rd) {
  vec4 col = vec4(0.0);
  vec2 env = trace(ro, rd);
  if (env.x != -1.0) {
    col = vec4(terrainColour(ro, rd, env), 1.0);
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

  vec3 colour = vec3(0.0);

  vec3 origin = vec3(0.0, 20.0, -40.0);
  origin.z += iGlobalTime * 1.5;
  origin.x += iGlobalTime;
  vec3 target = vec3(0.0, 0.0, 0.0);
  target.z += iGlobalTime * 1.5;
  target.x += iGlobalTime;
  mat3 toWorld = setCamera(origin, target, 0.0);
  vec3 rd = toWorld * normalize(vec3(p.xy, 1.25));

  // sky
  colour = renderSky(origin, rd);

  // terrain
  vec4 terrain = render(origin, rd);
  colour = colour * (1.0 - terrain.w) + terrain.xyz;

  // bird
  vec4 bird = renderBird(origin, rd);
  colour = colour * (1.0 - bird.w) + bird.xyz;

  gl_FragColor = vec4(colour, 1.0);
}
