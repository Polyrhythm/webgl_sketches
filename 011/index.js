const glsl = require('glslify');
const regl = require('regl')();
const mat4 = require('gl-mat4');
const camera = require('regl-camera')(regl, {
  center: [0, 50, 0],
  distance: 300,
  phi: 0.0,
  theta: 2.5,
});
const dragon = require('stanford-dragon/3');
const normals = require('angle-normals');

const floorVertices = [
  -1, 0, -1,
  -1, 0, +1,
  +1, 0, +1,
  +1, 0, -1,
];

const floorIndices = [
  0, 1, 2, 0, 2, 3
];

const floorUV = [
  0, 0,
  0, 1,
  1, 1,
  1, 0,
];

const drawDragon = regl({
  frag: glsl.file('./frag.glsl'),
  vert: glsl.file('./vert.glsl'),
  attributes: {
    position: dragon.positions,
    normal: normals(dragon.cells, dragon.positions),
  },
  elements: dragon.cells,
});

const drawPlane = regl({
  vert: glsl.file('./planeVert.glsl'),
  frag: glsl.file('./planeFrag.glsl'),
  attributes: {
    position: floorVertices,
    uv: floorUV,
  },
  uniforms: {
    normal: [0, 1, 0],
    transform: () => {
      let base = mat4.create();
      mat4.translate(base, base, [0, 25, 0]);
      mat4.scale(base, base, [100, 100, 100]);

      return base;
    },
  },
  elements: floorIndices,
});

regl.frame(({tick}) => {
  regl.clear({
    color: [0, 0, 0, 1],
    depth: 1,
  });

  camera(() => {
    drawPlane();
    drawDragon();
  });
});
