precision highp float;

#pragma glslify: lambert = require(glsl-diffuse-lambert)
#pragma glslify: toLinear = require(glsl-gamma/in)
#pragma glslify: toGamma = require(glsl-gamma/out)

varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vLightPos;

void main()
{
  vec3 n = normalize(vNormal);
  vec3 lightDir = normalize(vLightPos - vPosition);
  float diffuse = lambert(lightDir, n);

  vec3 baseColour = toLinear(vec3(1.0));
  vec3 lightColour = toLinear(vec3(1.0));

  vec3 colour = baseColour * lightColour * diffuse;
  gl_FragColor = toGamma(vec4(colour, 1.0));
}
