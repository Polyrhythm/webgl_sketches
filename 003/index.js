const glsl = require('glslify');
const regl = require('regl')();
const mousePos = require('mouse-position');

const mouse = mousePos();

const drawMax = regl({
  vert: glsl.file('./vert.glsl'),
  frag: glsl.file('./frag.glsl'),

  attributes: {
    position: [
      +0, -2,
      -2, +0,
      +2, +2
    ],
  },

  uniforms: {
    mousePos: ({viewportHeight}) => {
      return [mouse[0], -1.0 * (mouse[1] - viewportHeight)];
    },
    texture: regl.prop('video'),
    resolution: ({viewportWidth, viewportHeight}) => {
      return [viewportWidth, viewportHeight];
    },
    time: regl.context('time'),
  },
  count: 3,
});

require('resl')({
  manifest: {
    video: {
      type: 'video',
      src: 'assets/max.mp4',
      stream: true,
    },
  },

  onDone: ({video}) => {
    video.autoplay = true;
    video.loop = true;
    video.play();

    const texture = regl.texture(video);
    regl.frame(() => {
      drawMax({ video: texture.subimage(video) });
    });
  },
});
