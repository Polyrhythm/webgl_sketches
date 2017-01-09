precision highp float;

uniform float time;
uniform vec2 resolution;

float iSphere(vec3 p, float radius) {
  return length(p) - radius;
}

float map(vec3 p) {
  float d1 = iSphere(p, 0.25);

  return d1;
}

const int MAX_STEPS = 64;
const float FAR_CULL = 100.0;
const float EPSILON = 0.001;
float trace(vec3 ro, vec3 rd) {
  float t = 0.0;
  for (int i = 0; i < MAX_STEPS; i++) {
    float d = map(ro + rd * t);

    if (t > FAR_CULL) {
      return 0.0;
    }

    if (d <= EPSILON) {
      return 1.0;
    }

    t += d;
  }

  return 0.0;
}

vec3 getNormal(vec3 p) {
  vec2 eps = vec2(0.0, EPSILON);
  vec3 n;
  n.x = map(p + eps.yxx) - map(p - eps.yxx);
  n.y = map(p + eps.xyx) - map(p - eps.xyx);
  n.z = map(p + eps.xxy) - map(p - eps.xxy);

  return normalize(n);
}

const vec3 LIGHT_DIR = vec3(0.0, -1.0, 0.0);
vec3 calcDiffuse(vec3 n) {
  vec3 diffuseColor = vec3(1.0);
  vec3 diffuseIntensity = vec3(1.0);
  float incidence = clamp(dot(LIGHT_DIR, n), 0.0, 1.0);

  return diffuseColor * diffuseIntensity * incidence;
}

void main() {
  vec2 q = gl_FragCoord.xy / resolution.xy;
  vec2 p = 1.0 - 2.0 * q;
  p *= resolution.xy / resolution.x;
  vec3 colour = vec3(0.0);

  vec3 eye = vec3(0.0);
  vec3 forward = vec3(0.0, 0.0, 1.0);
  vec3 up = vec3(0.0, 1.0, 0.0);

  vec3 ro = vec3(p, -1.0);
  vec3 rd = forward;
  float t = trace(ro, rd);

  if (t == 1.0) {
    vec3 diffuseLightColor = vec3(1.0);
    colour = vec3(0.2, 0.4, 0.6);
    vec3 n = getNormal(ro);
    vec3 diffuse = calcDiffuse(n);

    // diffuse
    colour += diffuse;
  }

  gl_FragColor = vec4(vec3(colour), 1.0);
}
