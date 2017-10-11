precision highp float;

#pragma glslify: toGamma = require('glsl-gamma/out')

varying vec2 vUV;

uniform vec2 resolution;
uniform sampler2D albedo;

void main()
{
  vec3 colour = toGamma(texture2D(albedo, vUV).rgb);

  gl_FragColor = vec4(colour, 1.0);
}
