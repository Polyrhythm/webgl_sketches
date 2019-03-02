const regl = require('regl')({
	extensions: [
		'webgl_draw_buffers',
	]
});
const glsl = require('glslify');
const control = require('control-panel');

const vertices = [
  -1, -1, 0,
  -1, +1, 0,
  +1, +1, 0,
  +1, -1, 0
];

const uv = [
	0, 1,
	0, 0,
	1, 0,
	1, 1
];

const indices = [
  0, 1, 2, 0, 2, 3
];

const BLUR_RADIUS = 'BlurRadius';

const panel = control([
  {
    type: 'range',
    label: BLUR_RADIUS,
    min: 0,
    max: 8,
    initial: 2.5,
  },
], {
  title: 'Gaussian blur (2-pass)',
});

let blurUniform = 2;
panel.on('input', (data) => {
	blurUniform = data[BLUR_RADIUS];
});

const fbo = regl.framebuffer({
	color: [
		regl.texture({ type: 'uint8'}),
	],
});

const drawHorizontal = regl({
	frag: glsl('./fragHorizontal.glsl'),
	vert: glsl('./vert.glsl'),
	attributes: {
		position: vertices,
		uv: uv,
	},
	uniforms: {
		resolution: ({ viewportWidth, viewportHeight }) => [viewportWidth, viewportHeight],
		texture: regl.prop('texture'),
		radius: (context, props, batchId) => {
			return props.blurUniform;
		},
	},
	elements: indices,
	framebuffer: fbo
});

const drawVertical = regl({
	frag: glsl('./fragVertical.glsl'),
	vert: glsl('./vert.glsl'),
	attributes: {
		position: vertices,
		uv: uv,
	},
	uniforms: {
		resolution: ({ viewportWidth, viewportHeight }) => [viewportWidth, viewportHeight],
		texture: () => {
			return fbo.color[0];
		},
		radius: regl.prop('blurUniform'),
	},
	elements: indices,
});

require('resl')({
	manifest: {
		texture: {
			type: 'image',
			src: 'assets/lace.jpg',
			parser: (data) => {
				return regl.texture({
					data: data,
					mag: 'linear',
					min: 'linear',
				});
			}
		}
	},
	onError: (error) => {
		console.error(error);
	},
	onDone: ({texture}) => {
		regl.frame(({viewportWidth, viewportHeight}) => {
			fbo.resize(viewportWidth, viewportHeight);

			regl.clear({
				color: [0,0,0,1],
			});

			drawHorizontal({texture, blurUniform});
			drawVertical({blurUniform});
		});


	}
})