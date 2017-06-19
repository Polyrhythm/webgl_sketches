precision highp float;

#pragma glslify: envMapEquirect = require('./local_modules/glsl-envmap-equirect')
#pragma glslify: reinhard = require('./local_modules/glsl-tonemapping/reinhard')
#pragma glslify: naughtyDog = require('./local_modules/glsl-tonemapping/naughty-dog.glsl')
#pragma glslify: toGamma = require('glsl-gamma/out')

uniform mat4 inverseView;
uniform sampler2D envMap;
uniform bool gammaCorrectionUnf;
uniform float exposureUnf, tonemappingUnf;

varying vec3 ecPosition, ecNormal;

void main()
{
  vec3 ecEyeDir = normalize(-ecPosition);
  vec3 wcEyeDir = vec3(inverseView * vec4(ecEyeDir, 0.0));
  vec3 wcNormal = vec3(inverseView * vec4(ecNormal, 0.0));
  vec3 reflectionWorld = reflect(-wcEyeDir, normalize(wcNormal));

  vec4 colour = texture2D(envMap, envMapEquirect(reflectionWorld));
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
