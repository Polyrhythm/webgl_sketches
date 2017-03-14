precision highp float;

#define saturate(x) clamp(x, 0.0, 1.0)

varying vec3 vNormal;

void main()
{
  vec3 diffuseColour = vec3(0.2);
  float incidence = saturate(dot(normalize(vNormal), vec3(0.0, 1.0, 0.0)));
  vec3 Fd = diffuseColour * incidence;
  gl_FragColor = vec4(Fd, 1.0);
}
