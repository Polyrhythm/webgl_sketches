precision mediump float;
attribute vec3 position;
attribute vec2 uv;
varying vec2 vUV;

void main()
{
  vUV = uv;
  gl_Position = vec4(position, 1.0);
}
