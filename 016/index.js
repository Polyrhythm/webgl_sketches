const regl = require('regl')({
  extensions: [
    'webgl_draw_buffers',
    'oes_texture_float',
  ],
});
const dragon = require('stanford-dragon/3');
const near = 0.01;
const far = 100.0;
const camera = require('regl-camera')(regl, {
  distance: 10,
  phi: 0.7,
  theta: 1.5,
  center: [0, 1, 0],
  near, far,
});

const glsl = require('glslify');
const angleNormals = require('angle-normals');
const mat4 = require('gl-mat4');
const control = require('control-panel');

const MODEL_COLOUR = 'model colour';
const RED_OFFSET = 'red offset';
const GREEN_OFFSET = 'green offset';
const BLUE_OFFSET = 'blue offset';
const contorls = control([
  {
    type: 'color',
    label: MODEL_COLOUR,
    format: 'rgb',
    initial: 'rgb(255, 255, 255)'
  },
  {
    type: 'range',
    label: RED_OFFSET,
    min: 0,
    max: 1,
    step: 0.01,
    initial: 0.01,
  },
  {
    type: 'range',
    label: GREEN_OFFSET,
    min: 0,
    max: 1,
    step: 0.01,
    initial: 0.02,
  },
  {
    type: 'range',
    label: BLUE_OFFSET,
    min: 0,
    max: 1,
    step: 0.01,
    initial: 0.03,
  },
], {
  title: 'Chromatic aberration',
});

let modelColourUnf = [1, 1, 1];
let redOffsetUnf = 0.01;
let greenOffsetUnf = 0.02;
let blueOffsetUnf = 0.03;
contorls.on('input', (data) => {
  modelColourUnf = data[MODEL_COLOUR]
    .match(/\d+/g)
    .map((colour) => (colour / 255));

  redOffsetUnf = data[RED_OFFSET];
  greenOffsetUnf = data[GREEN_OFFSET];
  blueOffsetUnf = data[BLUE_OFFSET];
});

const fbo = regl.framebuffer({
  depth: true,
  color: [
    regl.texture({ type: 'float' }), // colour
  ],
});

const drawScene = regl({
  vert: glsl.file('./passThrough.vert'),
  frag: glsl.file('./dragonFrag.glsl'),
  attributes: {
    position: dragon.positions,
    normal: angleNormals(dragon.cells, dragon.positions),
  },
  uniforms: {
    modelColour: regl.prop('modelColour'),
    transformation: () => {
      const transform = mat4.create();
      mat4.scale(transform, transform, [0.03, 0.03, 0.03]);

      return transform;
    },
  },
  elements: dragon.cells,
  cull: {
    enable: true,
    face: 'back',
  },
  depth: {
    enable: true,
  },
  framebuffer: fbo,
});

const postProcess = regl({
  vert: glsl.file('./fullscreen.vert'),
  frag: glsl.file('./postProcess.frag'),
  attributes: {
    position: [
      -1, -1,
      -1, 1,
      1, 1,
      1, -1,
    ],
    uv: [
      0, 0,
      0, 1,
      1, 1,
      1, 0,
    ],
  },
  uniforms: {
    resolution: ({viewportWidth, viewportHeight}) =>
      [viewportWidth, viewportHeight],
    albedo: fbo.color[0],
    time: (context) => context.tick,
    redOffset: regl.prop('redOffsetUnf'),
    greenOffset: regl.prop('greenOffsetUnf'),
    blueOffset: regl.prop('blueOffsetUnf'),
  },
  elements: [0, 3, 2, 0, 2, 1],
  depth: {
    enable: false,
  },
});

regl.frame(({viewportWidth, viewportHeight}) => {
  fbo.resize(viewportWidth, viewportHeight);

  camera(() => {
    regl.clear({
      color: [0,0,0,1],
      depth: 1,
      framebuffer: fbo,
    });

    drawScene({modelColour: modelColourUnf});
    postProcess({redOffsetUnf, greenOffsetUnf, blueOffsetUnf});
  });
});
