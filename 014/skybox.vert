attribute vec4 position;

#pragma glslify: inverse = require('glsl-inverse')
#pragma glslify: transpose = require('glsl-transpose')

uniform mat4 view, projection;

varying vec3 wcNormal;

void main()
{
  mat4 inverseProjection = inverse(projection);
  mat3 inverseView = transpose(mat3(view));

  vec3 unprojected = (inverseProjection * position).xyz;
  wcNormal = inverseView * unprojected;

  gl_Position = position;
}
