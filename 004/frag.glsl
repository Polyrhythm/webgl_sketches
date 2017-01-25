// https://www.shadertoy.com/view/XlKSDR

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
  vec2 s1 = opUnion(
    vec2(sdSphere(p, 0.4), METAL),
    vec2(sdSphere(p + vec3(0.0, 0.0, 0.85), 0.4), METAL)
  );

  vec2 s2 = opUnion(
    s1,
    vec2(sdPlane(p + vec3(0.0, 0.4, 0.0)), CHECKER_MARBLE)
  );

  vec2 s3 = opUnion(
    s2,
    vec2(sdSphere(p - vec3(0.0, 0.0, 0.85), 0.4), METAL)
  );

  return s3;
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

// https://www.cs.cornell.edu/~srm/publications/EGSR07-btdf.pdf
float GGX(float linearRoughness, float NoH, const vec3 h) {
  float oneMinusNoHSquared = 1.0 - NoH * NoH;
  float a = NoH * linearRoughness;
  float k = linearRoughness / (oneMinusNoHSquared + a * a);
  float d = k * k * (1.0 / PI);

  return d;
}

float g1_smith(float VoH, float k) {
  return VoH / (VoH * (1.0 - k) + k);
}

// https://de45xmedrsdbp.cloudfront.net/Resources/files/2013SiggraphPresentationsNotes-26915738.pdf
float G_smith(float roughness, float NoV, float NoL) {
  float k = ((roughness + 1.0) * (roughness + 1.0)) / 8.0;
  return g1_smith(NoL, k) * g1_smith(NoV, k);
}

// http://igorsklyar.com/system/documents/papers/28/Schlick94.pdf
float schlick(float f0, float f90, float VoH) {
  return f0 + (f90 - f0) * pow(2.0, -5.55473 * VoH + -6.98316 * VoH);
}

vec3 schlick(const vec3 f0, float VoH) {
  return f0 + (vec3(1.0) - f0) * pow(2.0, -5.55473 * VoH + -6.98316 * VoH);
}

// https://disney-animation.s3.amazonaws.com/library/s2012_pbs_disney_brdf_notes_v2.pdf
float burley_diffuse(float linearRoughness, float NoV, float NoL, float LoH) {
  float f90 = 0.5 + 2.0 * linearRoughness * LoH * LoH;
  float lightScatter = schlick(1.0, f90, NoL);
  float viewScatter = schlick(1.0, f90, NoV);

  return lightScatter * viewScatter * (1.0 / PI);
}

float lambert() {
  return 1.0 / PI;
}

// ---------------------
// Indirect lighting
// ---------------------
vec3 sphericalHarmonics(const vec3 n) {
  // Irradiance from "Ditch River" IBL (http://www.hdrlabs.com/sibl/archive.html)
  return max(
    vec3(+0.754554516862612, +0.748542953903366, +0.79092151548539) +
    vec3(-0.083856548007422, +0.092533500963210, +0.322764661032516) * n.y +
    vec3(+0.308152705331738, +0.366796330467391, +0.466698182999906) * n.z +
    vec3(-0.188884931542396, -0.277402551592231, -0.377844212327557) * n.x,
    0.0
  );
}

// https://www.unrealengine.com/blog/physically-based-shading-on-mobile
vec2 envBRDFApprox(float roughness, float NoV) {
  const vec4 c0 = vec4(-1.0, -0.0275, -0.572, 0.022);
  const vec4 c1 = vec4(1.0, 0.0425, 1.040, -0.040);
  vec4 r = roughness * c0 + c1;
  float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;

  return vec2(-1.04, 1.04) * a004 + r.zw;
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

    float NoV = saturate(dot(n, v));
    float NoL = saturate(dot(n, l));
    float NoH = saturate(dot(n, h));
    float LoH = saturate(dot(l, h));

    vec3 baseColor = vec3(0.0);
    float roughness = 0.0;
    float metallic = 0.0;

    float intensity = 2.0;
    float indirectIntensity = 0.4;

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
    vec3 f0 = 0.04 * (1.0 - metallic) + baseColor.rgb * metallic;

    // shadows
    float occlusion = shadow(pos, l);

    // Specular lighting
    float D = GGX(linearRoughness, NoH, h);
    float G = G_smith(roughness, NoV, NoL);
    vec3 F = schlick(f0, LoH);
    vec3 Fs = (D * G * F) / (4.0 * NoV); // figure out why I can't do NoL * NoV

    // Diffuse lighting
    vec3 Fd = diffuseColour * burley_diffuse(linearRoughness, NoV, NoL, LoH);

    colour = Fd + Fs;
    colour *= (intensity * occlusion * NoL) * vec3(1.0);

    // Indirect diffuse
    vec3 indirectDiffuse = sphericalHarmonics(n) * lambert();
    vec2 indirectHit = trace(pos, r);
    vec3 indirectSpecular = vec3(0.65, 0.85, 1.0) + r.y * 0.72;

    if (indirectHit.y == CHECKER_MARBLE) {
      vec3 indirectPos = pos + indirectHit.x * r;
      float f = mod(floor(6.0 * indirectPos.z) + floor(6.0 * indirectPos.x), 2.0);
      indirectSpecular = 0.4 + f * vec3(0.6);
    } else if (indirectHit.y == METAL) {
      indirectSpecular = vec3(0.2, 0.4, 0.6);
    }

    vec2 envBRDF = envBRDFApprox(roughness, NoV);
    vec3 specularColor = f0 * envBRDF.x + envBRDF.y;
    vec3 ibl = diffuseColour * indirectDiffuse + indirectSpecular * specularColor;
    colour += ibl * indirectIntensity;
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
