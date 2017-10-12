precision highp float;

#pragma glslify: toGamma = require('glsl-gamma/out')

varying vec2 vUV;

uniform vec2 resolution;
uniform float time, redOffset, greenOffset, blueOffset;
uniform sampler2D albedo;

void main()
{
  vec2 uv = vUV;
   float red = toGamma(texture2D(albedo, uv + vec2(redOffset)).r);
   float green = toGamma(texture2D(albedo, uv + vec2(greenOffset)).g);
   float blue = toGamma(texture2D(albedo, uv + vec2(blueOffset)).b);

   vec3 colour = vec3(red, green, blue);

  gl_FragColor = vec4(colour, 1.0);
}
