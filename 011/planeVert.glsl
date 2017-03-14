attribute vec3 position;
attribute vec2 uv;

uniform mat4 projection, transform, view;
uniform vec3 normal;

varying vec3 vNormal;
varying vec2 vUV;

void main()
{
  vUV = uv;
  vNormal = normal;
  gl_Position = projection * view * transform * vec4(position, 1.0);
}
