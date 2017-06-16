const regl = require('regl')();
const glsl = require('glslify');
const radius = 1;
const sphere = require('primitive-sphere')(radius, {
  segments: 32,
});
const camera = require('regl-camera')(regl, {
  distance: 30,
  phi: 0.7,
  theta: 1.5,
  center: [0, 5, 0],
});

const draw = regl({
  vert: glsl.file('./vert.glsl'),
  frag: glsl.file('./frag.glsl'),
  attributes: {
    position: sphere.positions,
    normal: sphere.normals,
  },
  uniforms: {
    lightPos: [0, 5, 0],
  },
  elements: sphere.cells,
});

regl.frame(({ time }) => {
  regl.clear({ color: [0, 0, 0, 1] });
  camera(() => {
    draw();
  });
});
