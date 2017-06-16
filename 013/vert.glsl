attribute vec4 position;
attribute vec3 normal;

uniform mat4 projection, view;
uniform vec3 lightPos;

varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vLightPos;

void main()
{
  vec4 pos = projection * view * position;
  vPosition = pos.xyz;
  vNormal = normal;
  vLightPos = vec3(view * vec4(lightPos, 1.0));

  gl_Position = pos;
}
