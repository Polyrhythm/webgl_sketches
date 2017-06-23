#extension GL_EXT_draw_buffers : require

precision highp float;

uniform sampler2D albedo, depthTex;

varying vec2 vUV;

uniform vec2 texelSize;
uniform int orientation;
uniform float blurCoefficient;
uniform float focusDistance;
uniform float near;
uniform float far;
uniform float ppm;

float getBlurDiameter(float d)
{
  float dd = d * (far - near);
  float xd = abs(dd - focusDistance);
  float xdd = (dd < focusDistance) ?
    (focusDistance - xd) :
    (focusDistance + xd);
  float b = blurCoefficient * (xd / xdd);

  return b * ppm;
}

void main()
{
  const float MAX_BLUR_RADIUS = 10.0;
  vec4 colour = texture2D(albedo, vUV);

  float depth = texture2D(depthTex, vUV).r;
  float blurAmount = getBlurDiameter(depth);
  blurAmount = min(floor(blurAmount), MAX_BLUR_RADIUS);

  float count = 0.0;
  vec2 texelOffset;
  if (orientation == 0)
  {
    texelOffset = vec2(texelSize.x, 0.0);
  }
  else
  {
    texelOffset = vec2(0.0, texelSize.y);
  }

  if (blurAmount >= 1.0)
  {
    float halfBlur = blurAmount * 0.5;
    colour = vec4(0.0);

    for (float i = 0.0; i < MAX_BLUR_RADIUS; ++i)
    {
      if (i >= blurAmount) break;

      float offset = i - halfBlur;
      vec2 vOffset = vUV + (texelOffset * offset);

      colour += texture2D(albedo, vOffset);
      ++count;
    }
  }
  if (count > 0.0)
  {
    colour = colour / count;
  }

  if (orientation == 0) gl_FragData[2] = vec4(colour);
  else gl_FragData[0] = vec4(colour);
}
