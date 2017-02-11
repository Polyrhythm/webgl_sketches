const regl = require('regl')();
const glsl = require('glslify');

const vertices = [
  -1, -1, 0,
  -1, +1, 0,
  +1, +1, 0,
  +1, -1, 0
];

const indices = [
  0, 1, 2, 0, 2, 3
];

const drawScene = regl({
  frag: glsl.file('./frag.glsl'),
  vert: glsl.file('./vert.glsl'),
  attributes: {
    position: vertices,
  },
  uniforms: {
    iGlobalTime: regl.context('time'),
    iResolution: ({viewportWidth, viewportHeight}) => [viewportWidth, viewportHeight],
  },
  elements: indices,
});

regl.frame(() => {
  regl.clear({
    color: [0, 0, 0, 1],
  });

  drawScene();
})
