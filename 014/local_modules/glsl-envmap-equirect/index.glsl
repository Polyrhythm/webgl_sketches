#define PI 3.1415926
#define TwoPI (2.0 * PI)

vec2 envMapEquirect(vec3 wcNormal, float flipEnvMap)
{
  float phi = acos(wcNormal.y);
  float theta = atan(flipEnvMap * wcNormal.x, wcNormal.z) + PI;
  return vec2(theta / TwoPI, phi / PI);
}

vec2 envMapEquirect(vec3 wcNormal)
{
  return envMapEquirect(wcNormal, -1.0);
}

#pragma glslify: export(envMapEquirect)
