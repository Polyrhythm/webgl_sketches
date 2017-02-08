precision highp float;

attribute vec3 position, normal;
uniform mat4 projection, view, transformation;
uniform float time;

varying vec3 fragNormal, fragPosition;

void main() {
  fragNormal = vec3(view * transformation * vec4(normal, 0.0));
  fragPosition = vec3(view * transformation * vec4(position, 1.0));
  gl_Position = projection * view * transformation * vec4(position, 1.0);
}
