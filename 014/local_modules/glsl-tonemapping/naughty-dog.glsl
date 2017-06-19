float A = 0.15;
float B = 0.50;
float C = 0.10;
float D = 0.20;
float E = 0.02;
float F = 0.30;
float W = 11.2;

vec3 tonemap(vec3 x)
{
  return ((x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
}

vec3 unchartedTonemap(vec3 colour, float exposureBias, out vec3 whiteScale)
{
  colour *= exposureBias;
  whiteScale = tonemap(vec3(W));

  return tonemap(colour);
}

#pragma glslify: export(unchartedTonemap)
