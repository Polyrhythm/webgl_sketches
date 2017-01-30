const regl = require('regl')();
const camera = require('regl-camera')(regl, {
  distance: 100,
  phi: 0.3,
  theta: 1.3,
  center: [0, 5, 0],
});
const glsl = require('glslify');
const mat4 = require('gl-mat4');

const elementData = [];
const xzPosition = [];

const N = 64;
const size = 0.5;
const xmin = -size;
const xmax = +size;
const ymin = -size;
const ymax = +size;
let row, col;

for (row = 0; row <= N; row++) {
  let z = (row / N) * (ymax - ymin) + ymin;
  for (col = 0; col <= N; col++) {
    let x = (col / N) * (xmax - xmin) + xmin;
    xzPosition.push([x, z]);
  }
}

for (row = 0; row <= N - 1; row++) {
  for (col = 0; col <= N - 1; col++) {
    let i = row * (N + 1) + col;
    let i0 = i + 0;
    let i1 = i + 1;
    let i2 = i + (N + 1) + 0;
    let i3 = i + (N + 1) + 1;

    elementData.push([i3, i1, i0]);
    elementData.push([i0, i2, i3]);
  }
}

const elements = regl.elements({
  primitive: 'lines',
  type: 'uint16',
  count: elementData.length * 3,
  data: elementData,
});

const drawScene = regl({
  vert: glsl.file('./vert.glsl'),
  frag: glsl.file('./frag.glsl'),
  attributes: {
    xzPosition: regl.prop('xzPosition'),
  },
  uniforms: {
    resolution: ({ viewportWidth, viewportHeight }) => {
      return [viewportWidth, viewportHeight];
    },
    time: regl.context('time'),
  },
  elements: regl.prop('elements'),
});

regl.frame(({tick}) => {
  regl.clear({
    color: [0, 0, 0, 1],
    depth: 1,
  });
  camera(() => {
    drawScene({elements, xzPosition});
  });
});
