attribute vec3 position, normal;
uniform mat4 projection, view;

varying vec3 vNormal;

void main()
{
  vNormal = normal;
  gl_Position = projection * view * vec4(position, 1.0);
}
