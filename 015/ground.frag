precision highp float;

#pragma glslify: toLinear = require('glsl-gamma/in')
#pragma glslify: toGamma = require('glsl-gamma/out')

uniform vec3 groundColourUnf;

void main()
{
  vec3 colour = toLinear(groundColourUnf);

  colour = toGamma(colour);
  gl_FragColor = vec4(colour, 1.0);
}
