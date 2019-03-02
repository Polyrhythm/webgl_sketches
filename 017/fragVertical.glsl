precision mediump float;
varying vec2 vUV;
uniform float radius;
uniform vec2 resolution;
uniform sampler2D texture;

void main()
{
	vec2 uv = vUV;
	float blur = radius / resolution.x;

	float weights[4];
	weights[0] = 0.1964825502;
	weights[1] = 0.2969069647;
	weights[2] = 0.0944703979;
	weights[3] = 0.0103813624;

	float offsets[4];
	offsets[0] = 0.0;
	offsets[1] = 1.3846153846;
	offsets[2] = 3.2307692308;
	offsets[3] = 5.1764705882;

	vec4 accumColour = texture2D(texture, uv.xy) * weights[0];

	for (int i = 1; i < 4; i++)
	{
		accumColour += texture2D(texture, vec2(uv.x, uv.y - blur * offsets[i])) * weights[i];
		accumColour += texture2D(texture, vec2(uv.x, uv.y + blur * offsets[i])) * weights[i];
	}

	gl_FragColor = vec4(accumColour.rgb, 1);
}
