precision highp float;

varying vec3 vNormal;

void main()
{
  vec3 colour = normalize(vNormal);
  gl_FragColor = vec4(colour, 1.0);
}
