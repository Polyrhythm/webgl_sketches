precision highp float;

#pragma glslify: envMapEquirect = require('./local_modules/glsl-envmap-equirect')
#pragma glslify: reinhard = require('./local_modules/glsl-tonemapping/reinhard')
#pragma glslify: naughtyDog = require('./local_modules/glsl-tonemapping/naughty-dog.glsl')
#pragma glslify: toGamma = require('glsl-gamma/out')

varying vec3 wcNormal;

uniform sampler2D envMap;
uniform bool gammaCorrectionUnf;
uniform float exposureUnf, tonemappingUnf;

void main()
{
  vec3 N = normalize(wcNormal);

  vec4 colour = texture2D(envMap, envMapEquirect(N));
  colour.rgb *= exposureUnf;

  if (tonemappingUnf == 1.0)
  {
    colour.rgb = reinhard(colour.rgb);
  }
  else if (tonemappingUnf == 2.0)
  {
    vec3 whiteScale;
    colour.rgb = naughtyDog(colour.rgb, 2.0, whiteScale);
    colour.rgb *= whiteScale;
  }

  if (gammaCorrectionUnf)
  {
    colour = toGamma(colour);
  }

  gl_FragColor = colour;
}
