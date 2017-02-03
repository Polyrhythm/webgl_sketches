precision highp float;

attribute vec3 position, normal;
uniform mat4 projection, view, transformation;
uniform float time;

varying vec3 fragNormal, fragPosition;

void main() {
  fragNormal = (view * transformation * vec4(normal, 0.0)).xyz;
  fragPosition = position;
  gl_Position = projection * view * transformation * vec4(position, 1.0);
}
