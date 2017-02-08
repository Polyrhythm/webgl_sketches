precision highp float;

#define saturate(x) clamp(x, 0.0, 1.0)
#define PI 3.14159265359

const int NUM_LIGHTS = 2;

varying vec3 fragNormal, fragPosition;
struct Light {
  vec3 position;
  vec3 colour;
  float intensity;
};

uniform Light lights[NUM_LIGHTS];

// ----------
// BRDFs
// ----------
vec3 realtimeSpec(
  const float shininess,
  const float NoH,
  const float NoL,
  const vec3 specularColour) {
  float t1 = (shininess + 8.0) / (8.0 * PI);
  float t2 = pow(NoH, shininess);
  vec3 t3 = specularColour * NoL;

  return t1 * t2 * t3;
}

// ------------
// render
// ------------
vec3 render(vec3 colour, Light light) {
  vec3 baseColour = vec3(0.9, 0.1, 0.3);
  vec3 v = normalize(-fragPosition);
  vec3 n = normalize(fragNormal);
  vec3 l = normalize(light.position - fragPosition);
  vec3 h = normalize(v + l);
  vec3 d = normalize(l - h);

  float NoV = saturate(dot(n, v));
  float NoL = saturate(dot(n, l));
  float NoH = saturate(dot(n, h));
  float LoH = saturate(dot(l, h));

  vec3 f0 = baseColour + 0.04;
  float shininess = 80.0;

  // specular
  vec3 Fs = realtimeSpec(shininess, NoH, NoL, f0);

  colour += (baseColour / PI + Fs) * light.colour * light.intensity * NoL;

  return colour;
}

void main() {
  vec3 colour = vec3(0.0);
  for (int i = 0; i < NUM_LIGHTS; i++) {
    colour += render(colour, lights[i]);
  }

  gl_FragColor = vec4(colour, 1.0);
}
