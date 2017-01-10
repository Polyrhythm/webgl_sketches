const regl = require('regl')();
const glsl = require('glslify');

const drawScene = regl({
  vert: glsl.file('./vert.glsl'),
  frag: glsl.file('./frag.glsl'),
  attributes: {
    position: [
      +1, +1, +0,
      +1, -1, +0,
      -1, -1, +0,

      -1, +1, +0,
      +1, +1, +0,
      -1, -1, +0,
    ],
  },

  uniforms: {
    resolution: ({ viewportWidth, viewportHeight }) => {
      return [viewportWidth, viewportHeight];
    },
    time: regl.context('time'),
  },
  count: 6,
});

regl.frame(({tick}) => {
  regl.clear({
    color: [0, 0, 0, 1],
    depth: 1,
  });

  drawScene();
});
