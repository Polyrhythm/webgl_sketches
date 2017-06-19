const regl = require('regl')({
  extensions: ['oes_texture_float'],
});
const camera = require('regl-camera')(regl, {
  distance: 10,
  phi: 0.7,
  theta: 1.5,
  center: [0, 1, 0],
});
const glsl = require('glslify');
const parseHDR = require('parse-hdr');
const sphere = require('primitive-sphere')(1, {
  segments: 32,
});
const mat4 = require('gl-mat4');
const control = require('control-panel');

const GAMMA_CORRECTION = 'Gamma correction';
const EXPOSURE = 'Exposure';

const TONEMAPPING = 'Tonemapping';
const NONE = 'none';
const REINHARD = 'reinhard';
const NAUGHTY_DOG = 'naughty dog';

const tonemappingMap = {};
tonemappingMap[NONE] = 0;
tonemappingMap[REINHARD] = 1;
tonemappingMap[NAUGHTY_DOG] = 2;

const panel = control([
  {
    type: 'checkbox',
    label: GAMMA_CORRECTION,
    initial: true,
  },
  {
    type: 'range',
    label: EXPOSURE,
    min: 0,
    max: 4,
    initial: 1,
  },
  {
    type: 'select',
    label: TONEMAPPING,
    options: [NONE, REINHARD, NAUGHTY_DOG],
    initial: NONE,
  },
], {
  title: 'HDR',
});

let gammaCorrectionUnf = true;
let exposureUnf = 1;
let tonemappingUnf = tonemappingMap[NONE];
panel.on('input', (data) => {
  gammaCorrectionUnf = data[GAMMA_CORRECTION];
  exposureUnf = data[EXPOSURE];
  tonemappingUnf = tonemappingMap[data[TONEMAPPING]];
});

const drawBall = regl({
  vert: glsl.file('./reflection.vert'),
  frag: glsl.file('./reflection.frag'),
  attributes: {
    position: sphere.positions,
    normal: sphere.normals,
  },
  uniforms: {
    envMap: regl.prop('env'),
    inverseView: (context) => {
      const iView = mat4.create();
      mat4.invert(iView, context.view);

      return iView;
    },
    exposureUnf: regl.prop('exposureUnf'),
    gammaCorrectionUnf: regl.prop('gammaCorrectionUnf'),
    tonemappingUnf: regl.prop('tonemappingUnf'),
  },
  elements: sphere.cells,
});

const drawEnv = regl({
  vert: glsl.file('./skybox.vert'),
  frag: glsl.file('./skybox.frag'),
  attributes: {
    position: [
      -1, -1, 0, 1,
      +1, -1, 0, 1,
      +1, +1, 0, 1,
      -1, +1, 0, 1,
    ],
  },
  uniforms: {
    envMap: regl.prop('env'),
    exposureUnf: regl.prop('exposureUnf'),
    gammaCorrectionUnf: regl.prop('gammaCorrectionUnf'),
    tonemappingUnf: regl.prop('tonemappingUnf'),
  },
  elements: [0, 1, 2, 0, 2, 3],
  depth: {
    enable: false,
  },
});

require('resl')({
  manifest: {
    env: {
      type: 'binary',
      src: './assets/pisa.hdr',
      parser: (data) => {
        const hdr = parseHDR(data);

        return regl.texture({
          width: hdr.shape[0],
          height: hdr.shape[1],
          data: hdr.data,
          type: 'float',
        });
      },
    },
  },

  onDone: ({env}) => {
    regl.frame(() => {
      regl.clear({
        color: [0, 0, 0, 1],
        depth: 1,
      });

      camera(() => {
        drawEnv({
          env,
          gammaCorrectionUnf,
          exposureUnf,
          tonemappingUnf,
        });
        drawBall({
          env,
          gammaCorrectionUnf,
          exposureUnf,
          tonemappingUnf,
        });
      });
    });
  },

  onError: (err) => {
    console.error(err);
  },
});
