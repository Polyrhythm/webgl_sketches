precision highp float;

// Constants
#define PI 3.14159265359

// Material definitions
#define METAL 1.0
#define CHECKER_MARBLE 2.0

// Uniforms
uniform float time;
uniform vec2 resolution;

// ------------------------
// Scene description
// ------------------------
float sdSphere(vec3 p, float radius) {
  return length(p) - radius;
}

float sdPlane(vec3 p) {
  return p.y;
}

vec2 opUnion(vec2 d1, vec2 d2) {
  return d1.x < d2.x ? d1 : d2;
}

// Shapes stores as vec2s:
// x stores distance scalar
// y stores material
vec2 map(vec3 p) {
  vec2 scene = opUnion(
    vec2(sdSphere(p, 0.4), METAL),
    vec2(sdPlane(p + vec3(0.0, 0.4, 0.0)), CHECKER_MARBLE)
  );

  return scene;
}

// -------------------------
// TRACE THEM RAYS
// -------------------------
const int MAX_STEPS = 12;
const float FAR_CULL = 10.0;
const float EPSILON = 0.002;
vec2 trace(vec3 ro, vec3 rd) {
  float t = 0.02;
  float material = -1.0;
  for (int i = 0; i < MAX_STEPS; i++) {
    vec2 d = map(ro + rd * t);

    if (t > FAR_CULL || d.x < EPSILON) {
      break;
    }

    t += d.x;
    material = d.y;
  }

  if (t > FAR_CULL) {
    material = -1.0;
  }

  return vec2(t, material);
}

vec3 getNormal(vec3 p) {
  vec2 eps = vec2(0.0, EPSILON);
  vec3 n;
  n.x = map(p + eps.yxx).x - map(p - eps.yxx).x;
  n.y = map(p + eps.xyx).x - map(p - eps.xyx).x;
  n.z = map(p + eps.xxy).x - map(p - eps.xxy).x;

  return normalize(n);
}

// ---------------------------
// BRDFs and friends
// ---------------------------
const vec3 LIGHT_DIR = vec3(0.0, -1.0, 0.0);
vec3 calcDiffuse(vec3 n) {
  vec3 diffuseColor = vec3(1.0);
  vec3 diffuseIntensity = vec3(1.0);
  float incidence = clamp(dot(-LIGHT_DIR, n), 0.0, 1.0);

  return diffuseColor * diffuseIntensity * incidence;
}

// ---------------------
// Rendering
// ---------------------
vec3 render(vec3 ro, vec3 rd, out float dist) {
  // Sky color
  vec3 colour = vec3(0.65, 0.85, 1.0) + rd.y * 0.72;
  vec2 hit = trace(ro, rd);
  dist = hit.x;
  float material = hit.y;

  if (material > 0.0) {
    colour = vec3(0.0);
    vec3 pos = ro + rd * dist;
    vec3 n = getNormal(pos);

    if (material == METAL) {
      colour = n;
    }

    if (material == CHECKER_MARBLE) {
      float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
      colour = 0.4 + f * vec3(0.6);
    }
  }

  return colour;
}

// ---------------------
// Setup
// ---------------------
mat3 setCamera(in vec3 origin, in vec3 target, float rotation) {
    vec3 forward = normalize(target - origin);
    vec3 orientation = vec3(sin(rotation), cos(rotation), 0.0);
    vec3 left = normalize(cross(forward, orientation));
    vec3 up = normalize(cross(left, forward));
    return mat3(left, up, forward);
}

void main() {
  vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
  p *= resolution.xy / resolution.y;

  vec3 origin = vec3(0.0, 0.8, 0.0);
  vec3 target = vec3(0.0);

  origin.x += 1.7 * cos(time * 0.2);
  origin.z += 1.7 * sin(time * 0.2);

  mat3 toWorld = setCamera(origin, target, 0.0);
  vec3 rd = toWorld * normalize(vec3(p.xy, 1.25));

  float dist;
  vec3 colour = render(origin, rd, dist);

  gl_FragColor = vec4(vec3(colour), 1.0);
}
