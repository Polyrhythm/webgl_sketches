vec3 reinhard(vec3 colour)
{
  return colour / (colour + vec3(1.0));
}

#pragma glslify: export(reinhard)
