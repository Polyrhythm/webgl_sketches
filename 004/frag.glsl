precision highp float;

#define PI 3.14159265359
#define saturate(x) clamp(x, 0.0, 1.0)

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
const int MAX_STEPS = 128;
const float FAR_CULL = 25.0;
const float EPSILON = 0.002;

float shadow(vec3 ro, vec3 rd) {
  float hit = 1.0;
  float t = 0.02;
  for (int i = 0; i < MAX_STEPS; i++) {
    float h = map(ro + rd * t).x;

    if (h < EPSILON) return 0.0;
    t += h;
    hit = min(hit, 10.0 * h / t);
    if (t >= FAR_CULL / 10.0) break;
  }

  return clamp(hit, 0.0, 1.0);
}

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
const vec3 LIGHT_POS = vec3(0.6, 0.7, -0.7);
float lambert(vec3 pos, vec3 n) {
  return clamp(dot(normalize(LIGHT_POS - pos), n), 0.0, 1.0);
}

// http://igorsklyar.com/system/documents/papers/28/Schlick94.pdf
float schlick(float f0, float f90, float VoH) {
  return f0 + (f90 - f0) * pow(1.0 - VoH, 5.0);
}

// https://disney-animation.s3.amazonaws.com/library/s2012_pbs_disney_brdf_notes_v2.pdf
float burley_diffuse(float linearRoughness, float NoV, float NoL, float LoH) {
  float f90 = 0.5 + 2.0 * linearRoughness * LoH * LoH;
  float lightScatter = schlick(1.0, f90, NoL);
  float viewScatter = schlick(1.0, f90, NoV);

  return lightScatter * viewScatter * (1.0 / PI);
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
    vec3 pos = ro + rd * dist;
    vec3 v = normalize(-rd);
    vec3 n = getNormal(pos);
    vec3 l = normalize(LIGHT_POS);
    vec3 h = normalize(v + l);
    vec3 d = normalize(l - h);
    vec3 r = normalize(reflect(rd, n));

    float NoV = abs(dot(n, v)) + 1e-5;
    float NoL = saturate(dot(n, l));
    float NoH = saturate(dot(n, h));
    float LoH = saturate(dot(l, h));

    vec3 baseColor = vec3(0.0);
    float roughness = 0.0;
    float metallic = 0.0;

    float intensity = 2.0;

    if (material == METAL) {
      roughness = 0.2;
      baseColor = vec3(0.2, 0.4, 0.6);
    }

    if (material == CHECKER_MARBLE) {
      float f = mod(floor(2.0 * pos.z) + floor(2.0 * pos.x), 2.0);
      baseColor = 0.4 + f * vec3(0.6);
    }

    float linearRoughness = roughness * roughness;
    vec3 diffuseColour = (1.0 - metallic) * baseColor.rgb;

    // shadows
    float occlusion = shadow(pos, l);

    // Diffuse BRDF
    vec3 Fd = diffuseColour * burley_diffuse(linearRoughness, NoV, NoL, LoH);

    colour = Fd;
    colour *= (intensity * occlusion * NoL) * vec3(1.0);
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

  // Fog
  colour = mix(
    colour,
    1.2 * vec3(0.7, 0.8, 1.0), 1.0 - exp2(-0.011 * dist * dist)
  );

  gl_FragColor = vec4(vec3(colour), 1.0);
}
