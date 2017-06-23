#extension GL_EXT_draw_buffers : require

precision highp float;

#pragma glslify: toLinear = require('glsl-gamma/in')

uniform vec3 groundColourUnf;
uniform float far, near;

varying vec3 vPosition;

void main()
{
  vec3 colour = toLinear(groundColourUnf);
  float depth = length(vPosition) / (far - near);

  gl_FragData[0] = vec4(colour, 1.0);
  gl_FragData[1] = vec4(vec3(depth), 0.0);
}
