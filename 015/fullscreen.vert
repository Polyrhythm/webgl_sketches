attribute vec2 position, uv;

varying vec2 vUV;

void main()
{
  vUV = uv;
  gl_Position = vec4(position, 0.0, 1.0);
}
