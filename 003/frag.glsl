precision highp float;

uniform sampler2D texture;
uniform vec2 resolution;
uniform float time;
uniform vec2 mousePos;

varying vec2 uv;

vec4 blur(sampler2D image, vec2 uv, vec2 resolution, vec2 direction) {
  vec4 color = vec4(0.0);
  vec2 off1 = vec2(10.3846153846) * direction + sin(time) * 10.0;
  vec2 off2 = vec2(30.2307692308) * direction + cos(time) * 15.0;
  color += texture2D(image, uv) * 0.2270270270;
  color += texture2D(image, uv + (off1 / resolution)) * 0.3162162162;
  color += texture2D(image, uv - (off1 / resolution)) * 0.3162162162;
  color += texture2D(image, uv + (off2 / resolution)) * 0.0702702703;
  color += texture2D(image, uv - (off2 / resolution)) * 0.0702702703;
  return color;
}

void main() {
  vec2 q = gl_FragCoord.xy;
  vec2 p = q / resolution;
  p = 1.0 - 2.0 * p;
  vec4 colour;

  if (distance(q, mousePos) <= 100.0) {
    colour = texture2D(texture, uv);
  } else {
    colour = blur(texture, uv, resolution.xy, vec2(1.0, 0.0));
  }

  gl_FragColor = colour;
}
