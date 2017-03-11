const regl = require('regl')();
const glsl = require('glslify');
const touch = require('touches');

let posX = posY = 0;

touch(window)
  .on('move', (ev, position) => {
    posX = position[0];
    posY = position[1];
  });

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
    lightDir: [0.5, 0.5, 0.7],
    mousePos: (context, props) => {
      return [props.posX, props.posY];
    },
  },
  count: 6,
});

regl.frame(({tick}) => {
  regl.clear({
    color: [0, 0, 0, 1],
    depth: 1,
  });
  drawScene({ posX, posY });
});
