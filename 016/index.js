const regl = require('regl')({
  extensions: [
    'webgl_draw_buffers',
    'oes_texture_float',
  ],
});
const dragon = require('stanford-dragon/3');
const near = 0.01;
const far = 100.0;
const camera = require('regl-camera')(regl, {
  distance: 10,
  phi: 0.7,
  theta: 1.5,
  center: [0, 1, 0],
  near, far,
});

const glsl = require('glslify');
const angleNormals = require('angle-normals');
const mat4 = require('gl-mat4');

const fbo = regl.framebuffer({
  depth: true,
  color: [
    regl.texture({ type: 'float' }), // colour
  ],
});

const drawScene = regl({
  vert: glsl.file('./passThrough.vert'),
  frag: glsl.file('./dragonFrag.glsl'),
  attributes: {
    position: dragon.positions,
    normal: angleNormals(dragon.cells, dragon.positions),
  },
  uniforms: {
    modelColour: [0.1, 0.0, 0.3],
    transformation: () => {
      const transform = mat4.create();
      mat4.identity(transform);

      return transform;
    },
  },
  elements: dragon.cells,
  cull: {
    enable: true,
    face: 'back',
  },
  depth: {
    enable: true,
  },
  framebuffer: fbo,
});

const postProcess = regl({
  vert: glsl.file('./fullscreen.vert'),
  frag: glsl.file('./postProcess.frag'),
  attributes: {
    position: [
      -1, -1,
      -1, 1,
      1, 1,
      1, -1,
    ],
    uv: [
      0, 0,
      0, 1,
      1, 1,
      1, 0,
    ],
  },
  uniforms: {
    resolution: ({viewportWidth, viewportHeight}) =>
      [viewportWidth, viewportHeight],
    albedo: fbo.color[0],
  },
  elements: [0, 3, 2, 0, 2, 1],
  depth: {
    enable: false,
  },
});

regl.frame(({viewportWidth, viewportHeight}) => {
  fbo.resize(viewportWidth, viewportHeight);

  camera(() => {
    regl.clear({
      color: [0,0,0,1],
      depth: 1,
      framebuffer: fbo,
    });

    drawScene();
    postProcess();
  });
});
