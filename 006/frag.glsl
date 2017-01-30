precision highp float;

#define PI 3.14159265359
#define saturate(x) clamp(x, 0.0, 1.0)

uniform float diffuseIntensity;
uniform vec3 lightDir;
uniform vec2 resolution;
uniform float time;

varying vec3 vNormal;
varying vec4 vPosition;

// ----------
// BRDFs
// ----------
float g1_smith(float VoH, float k) {
  return VoH / (VoH * (1.0 - k) + k);
}

float G_smith(float roughness, float NoV, float NoL) {
  float k = ((roughness + 1.0) * (roughness + 1.0)) / 8.0;
  return g1_smith(NoL, k) * g1_smith(NoV, k);
}

float GGX(float linearRoughness, float NoH, const vec3 h) {
  float oneMinusNoHSquared = 1.0 - NoH * NoH;
  float a = NoH * linearRoughness;
  float k = linearRoughness / (oneMinusNoHSquared + a * a);
  float d = k * k * (1.0 / PI);

  return d;
}

vec3 schlick(const vec3 f0, float VoH) {
  return f0 + (vec3(1.0) - f0) * pow(2.0, -5.55473 * VoH + -6.98316 * VoH);
}

// -----------
// Rendering
// -----------
vec3 render() {
  vec3 colour = vec3(0.0);
  vec3 n = vNormal;
  vec3 l = normalize(lightDir);
  vec3 v = normalize(-vPosition.xyz);
  vec3 h = normalize(v + l);
  vec3 d = normalize(l - h);

  float NoV = saturate(dot(n, v));
  float NoL = saturate(dot(n, l));
  float NoH = saturate(dot(n, h));
  float LoH = saturate(dot(l, h));

  vec3 baseColour = mix(vec3(0.0, 0.1, 0.6), vec3(0.3, 0.15, 0.4), NoV);
  float roughness = 0.6;
  float linearRoughness = roughness * roughness;
  vec3 f0 = baseColour + 0.04;

  // diffuse
  vec3 Fd = baseColour * NoL;

  // specular
  float D = GGX(linearRoughness, NoH, h);
  float G = G_smith(roughness, NoV, NoL);
  vec3 F = schlick(f0, LoH);
  vec3 Fs = (D * G * F) / (4.0 * NoL);

  colour = Fd + Fs;

  return colour;
}

// -----------
// Setup
// -----------
void main() {
  vec3 colour = render();

  gl_FragColor = vec4(colour, 1.0);
}
