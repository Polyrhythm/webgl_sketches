precision highp float;

#pragma glslify: lambert = require(glsl-diffuse-lambert)

varying vec3 vPosition;
varying vec3 vNormal;
varying vec3 vLightPos;

void main()
{
  vec3 n = normalize(vNormal);
  vec3 lightDir = normalize(vLightPos - vPosition);
  float diffuse = lambert(lightDir, n);

  vec3 baseColour = vec3(1.0);
  vec3 lightColour = vec3(1.0);

  vec3 colour = baseColour * lightColour;
  gl_FragColor = vec4(colour, 1.0);
}
