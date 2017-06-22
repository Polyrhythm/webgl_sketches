attribute vec3 position, normal;

uniform mat4 view, projection;
uniform mat4 transformation;

varying vec3 vNormal;
varying vec2 vUV;

void main()
{
  vNormal = normal;
  gl_Position = vec4(projection * view * transformation * vec4(position, 1.0));
}
