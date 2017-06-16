precision highp float;

#pragma glslify: lambert = require(glsl-diffuse-lambert)
#pragma glslify: toLinear = require(glsl-gamma/in)
#pragma glslify: toGamma = require(glsl-gamma/out)

varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vLightPos;
varying vec2 vUV;

uniform sampler2D tex;
uniform bool linearColours;
uniform bool gammaCorrection;
uniform vec3 lightColourUnf;

void main()
{
  vec3 n = normalize(vNormal);
  vec3 lightDir = normalize(vLightPos - vPosition);
  float diffuse = lambert(lightDir, n);

  vec3 baseColour = texture2D(tex, vUV).rgb;
  vec3 lightColour = lightColourUnf;

  if (linearColours)
  {
    baseColour = toLinear(baseColour);
    lightColour = toLinear(lightColour);
  }

  vec3 colour = baseColour * lightColour * diffuse;

  if (gammaCorrection)
  {
    colour = toGamma(colour);
  }

  gl_FragColor = vec4(colour, 1.0);
}
