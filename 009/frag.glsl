precision highp float;

uniform sampler2D texture;

varying vec2 uv;

void main()
{
  vec3 colour = texture2D(texture, uv).xyz;

  gl_FragColor = vec4(colour, 1.0);
}
