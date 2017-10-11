#extension GL_EXT_draw_buffers : require

precision highp float;

#pragma glslify: toLinear = require('glsl-gamma/in')

uniform vec3 modelColour;
varying vec3 vNormal, vPosition;

void main()
{
  vec3 colour = toLinear(modelColour);
  float diffuse = max(0.0, dot(vec3(0, 1, 0), normalize(vNormal)));
  colour *= diffuse;

  gl_FragData[0] = vec4(colour, 1.0);
}
