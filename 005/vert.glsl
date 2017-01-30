#pragma glslify: snoise3 = require('glsl-noise/simplex/3d')

precision highp float;

#define WORLD_SIZE 300.0
#define WORLD_HEIGHT 100.0

attribute vec2 xzPosition;
varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vColor;

uniform mat4 projection, view;
uniform float time;

vec3 getPos(const vec2 xz) {
  float height = snoise3(vec3(xz, time * 0.1));
  return vec3(WORLD_SIZE * xz.x, height * 10.0, WORLD_SIZE * xz.y);
}

void main() {
  vec3 xyzPosition = getPos(xzPosition);
  vec3 normal = vec3(0.0, 1.0, 0.0);
  vNormal = normal;
  vPosition = xyzPosition;
  vColor = vec3(xzPosition.x, xyzPosition.y, xzPosition.y) + vec3(0.2, 0.4, 0.6);

  gl_Position = projection * view * vec4(xyzPosition, 1.0);
}
