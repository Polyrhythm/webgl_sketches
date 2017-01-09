precision highp float;

attribute vec2 position;
varying vec2 uv;

vec2 flipH(vec2 v) {
  return v * vec2(-1.0, 1.0);
}

void main() {
  uv = position;
  gl_Position = vec4(flipH(1.0 - 2.0 * position), 0.0, 1.0);
}
