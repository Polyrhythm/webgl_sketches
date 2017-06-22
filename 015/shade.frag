precision highp float;

#pragma glslify: toLinear = require('glsl-gamma/in')
#pragma glslify: toGamma = require('glsl-gamma/out')

uniform vec3 modelColour;

varying vec3 vNormal;

void main()
{
  vec3 colour = toLinear(modelColour);
  float diffuse = max(0.0, dot(vec3(0, 1, 0), normalize(vNormal)));
  colour = toGamma(colour * diffuse);
  gl_FragColor = vec4(colour, 1.0);
}
