const regl = require('regl')();
const glsl = require('glslify');

const drawVideo = regl({
  frag: glsl.file('./frag.glsl'),
  vert: glsl.file('./vert.glsl'),

  attributes: {
    position: [
      -2, +0,
      +0, -2,
      +2, +2,
    ],
  },

  uniforms: {
    texture: regl.prop('video'),
  },

  count: 3,
});

require('resl')({
  manifest: {
    video: {
      type: 'video',
      src: 'assets/bunny.ogv',
      stream: true,
    }
  },

  onError: (error) => {
    console.log('error, error! ', error);
  },

  onDone: ({video}) => {
    video.autoplay = true;
    video.loop = true;
    video.play();

    const tex = regl.texture(video);

    regl.frame(() => {
      drawVideo({ video: tex.subimage(video) });
    })
  }
});
