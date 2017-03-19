const glsl = require('glslify');
const regl = require('regl')({
  extensions: 'oes_texture_float',
});

const verts = [
  -1, -1,
  -1, +1,
  +1, +1,
  +1, -1,
];

const uv = [
  0, 0,
  0, 1,
  1, 1,
  1, 0,
];

const indices = [
  0, 1, 2, 2, 3, 0
];

const width = 512;
const height = 512;

function getInitCond() {
  let a = new Array(4 * width * height);
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const i = width * y + x;
      const centralSquare = (
        x > width / 2 - 10 &&
        x < width / 2 + 10 &&
        y > height / 2 - 10 &&
        y < height / 2 + 10
      );

      if (centralSquare) {
        a[4 * i + 0] = 0.5 + Math.random() * 0.02 - 0.01;
        a[4 * i + 1] = 0.25 + Math.random() * 0.02 - 0.01;
      } else {
        a[4 * i + 0] = 1.0;
        a[4 * i + 1] = 0;
      }
    }
  }

  return a;
}

const framebuffers = (Array(2)).fill().map(() =>
  regl.framebuffer({
    color: regl.texture({
      width: width,
      height: height,
      data: getInitCond(),
      format: 'rgba',
      type: 'float',
      wrap: 'repeat'
    }),
  })
);

const drawQuad = regl({
  vert: glsl.file('./vert.glsl'),
  frag: glsl.file('./frag.glsl'),

  framebuffer: ({tick}) => framebuffers[(tick + 1) % 2],
});

const seeQuad = regl({
  vert: glsl.file('./vert.glsl'),
  frag: glsl.file('./seeFrag.glsl'),
  attributes: {
    position: verts,
    uv: uv,
  },
  uniforms: {
    resolution: ({viewportWidth, viewportHeight}) =>
      [viewportWidth, viewportHeight],
    tex: ({tick}) => framebuffers[tick % 2],
  },
  elements: indices,
  depth: { enable: false },
});

regl.frame(({tick}) => {
  seeQuad(() => {
    drawQuad();
    regl.draw();
  });
});
