precision highp float;

#define saturate(x) clamp(x, 0.0, 1.0)

uniform float time;
uniform vec2 resolution;
uniform vec3 lightDir;

float hash(vec3 p)
{
    p  = 50.0 * fract(p * 0.3183099);
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

vec4 noised(in vec3 x)
{
    vec3 p = floor(x);
    vec3 w = fract(x);

    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);
    vec3 du = 30.0*w*w*(w*(w-2.0)+1.0);

    float a = hash(p + vec3(0,0,0));
    float b = hash(p + vec3(1,0,0));
    float c = hash(p + vec3(0,1,0));
    float d = hash(p + vec3(1,1,0));
    float e = hash(p + vec3(0,0,1));
    float f = hash(p + vec3(1,0,1));
    float g = hash(p + vec3(0,1,1));
    float h = hash(p + vec3(1,1,1));

    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return vec4( -1.0+2.0*(k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z),
                      2.0* du * vec3( k1 + k4*u.y + k6*u.z + k7*u.y*u.z,
                                      k2 + k5*u.z + k4*u.x + k7*u.z*u.x,
                                      k3 + k6*u.x + k5*u.y + k7*u.x*u.y ) );
}

const mat3 m3  = mat3( 0.00,  0.80,  0.60,
                      -0.80,  0.36, -0.48,
                      -0.60, -0.48,  0.64 );
const mat3 m3i = mat3( 0.00, -0.80, -0.60,
                       0.80,  0.36, -0.48,
                       0.60, -0.48,  0.64 );

vec4 fbm(in vec3 x)
{
    float f = 1.98;
    float s = 0.49;
    float a = 0.0;
    float b = 0.5;
    vec3  d = vec3(0.0);
    mat3  m = mat3(1.0,0.0,0.0,
                   0.0,1.0,0.0,
                   0.0,0.0,1.0);
    const int octaves = 8;
    for( int i=0; i < octaves; i++ )
    {
        vec4 n = noised(x);
        a += b*n.x;
        d += b*m*n.yzw;
        b *= s;
        x = f*m3*x;
        m = f*m3i*m;
    }
	return vec4( a, d );
}

void main()
{
  vec2 q = gl_FragCoord.xy / resolution.xy;
  vec2 uv = -1.0 + 2.0 * q;
  q.x *= resolution.x / resolution.y;

  vec4 noise = fbm(vec3(uv.xy * 0.1, time * 0.005));
  vec3 n = normalize(noise.yzw);
  float incidence = saturate(dot(n, normalize(lightDir)));
  vec3 diffuseColour = vec3(0.2, 0.4, 0.6);

  vec3 Fd = diffuseColour * incidence;

  gl_FragColor = vec4(Fd, 1.0);
}
