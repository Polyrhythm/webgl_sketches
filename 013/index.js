const regl = require('regl')({
  extensions: ['EXT_sRGB'],
});
const glsl = require('glslify');
const radius = 1;
const sphere = require('primitive-sphere')(radius, {
  segments: 32,
});
const camera = require('regl-camera')(regl, {
  distance: 10,
  phi: 0.7,
  theta: 1.5,
  center: [0, 1, 0],
});
const control = require('control-panel');

const LINEAR_COLOURS = 'Linear colours';
const GAMMA_CORRECTION = 'Gamma correction';

let linearColoursUnf = true;
let gammaCorrectionUnf = true;

const panel = control([
  {
    type: 'checkbox',
    label: 'Linear colours',
    initial: true,
  },
  {
    type: 'checkbox',
    label: 'Gamma correction',
    initial: true,
  },
], {
  title: 'Colour space demonstration',
});

panel.on('input', (data) => {
  linearColoursUnf = data[LINEAR_COLOURS];
  gammaCorrectionUnf = data[GAMMA_CORRECTION];
});

const draw = regl({
  vert: glsl.file('./vert.glsl'),
  frag: glsl.file('./frag.glsl'),
  attributes: {
    position: sphere.positions,
    normal: sphere.normals,
    uv: sphere.uvs,
  },
  uniforms: {
    lightPos: [0, 5, 0],
    tex: regl.prop('texture'),
    linearColours: regl.prop('linearColoursUnf'),
    gammaCorrection: regl.prop('gammaCorrectionUnf'),
    lightColourUnf: [1, 1, 1],
  },
  elements: sphere.cells,
});

require('resl')({
  manifest: {
    texture: {
      type: 'image',
      src: `assets/Pink_tile_pxr128.jpg`,
      parser: (data) => {
        return regl.texture({
          data: data,
          mag: 'linear',
          min: 'linear',
        });
      },
    }
  },
  onError: (err) => {
    console.error(err);
  },
  onDone: ({texture}) => {
    regl.frame(() => {
      regl.clear({
        color: [0, 0, 0, 1],
        depth: 1,
      });

      camera(() => {
        draw({linearColoursUnf, gammaCorrectionUnf, texture});
      });
    });
  },
});
