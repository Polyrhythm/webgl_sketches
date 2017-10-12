attribute vec3 position, normal;

uniform mat4 view, projection, transformation;

varying vec3 vNormal;
varying vec2 vUV;
varying vec3 vPosition;

void main()
{
  vNormal = normal;
  vec4 pos = view * transformation * vec4(position, 1.0);
  vPosition = pos.xyz;
  gl_Position = projection * pos;
}
