#pragma glslify: snoise3 = require('glsl-noise/simplex/3d')

precision highp float;

#define WORLD_SIZE 300.0
#define WORLD_HEIGHT 100.0

attribute vec2 xzPosition;
varying vec3 vNormal;
varying vec4 vPosition;

uniform mat4 projection, view;
uniform float time;

float getHeight(const vec2 xz) {
  return snoise3(vec3(xz, time * 0.1));
}

vec3 getPos(const vec2 xz) {
  float height = getHeight(xz);
  return vec3(WORLD_SIZE * xz.x, height * 10.0, WORLD_SIZE * xz.y);
}

vec3 getNormal(const vec2 xz) {
  float eps = 1.0 / 16.0;

  vec3 va = vec3(2.0 * eps,
                 getHeight(xz + vec2(eps, 0.0)) - getHeight(xz - vec2(eps, 0.0)),
                 0.0);
  vec3 vb = vec3(0.0,
                 getHeight(xz + vec2(0.0, eps)) - getHeight(xz - vec2(0.0, eps)),
                 2.0 * eps);

  return normalize(cross(normalize(vb), normalize(va)));
}

void main() {
  vec3 xyzPosition = getPos(xzPosition);
  vPosition = view * vec4(xyzPosition, 1.0);
  vNormal = getNormal(xzPosition);

  gl_Position = projection * view * vec4(xyzPosition, 1.0);
}
