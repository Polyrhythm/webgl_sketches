attribute vec3 normal, position;
attribute vec2 uv;

uniform mat4 projection, view;
uniform vec3 lightPos;

varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vLightPos;
varying vec2 vUV;

void main()
{
  vec4 pos = projection * view * vec4(position, 1.0);
  vPosition = pos.xyz;
  vNormal = normal;
  vLightPos = vec3(view * vec4(lightPos, 1.0));
  vUV = uv;

  gl_Position = pos;
}
