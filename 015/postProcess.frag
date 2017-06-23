precision highp float;

#pragma glslify: toGamma = require('glsl-gamma/out')

varying vec2 vUV;

uniform sampler2D albedo, depth, blur;

void main()
{
  vec3 colour = toGamma(texture2D(blur, vUV).rgb);

  gl_FragColor = vec4(colour, 1.0);
}
