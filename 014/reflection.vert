attribute vec3 position;
attribute vec3 normal;

uniform mat4 projection, view;

varying vec3 ecPosition, ecNormal;

void main()
{
  ecPosition = vec3(view * vec4(position, 1));
  ecNormal = normal;

  gl_Position = projection * view * vec4(position, 1);
}
