const regl = require('regl')();
const angleNormals = require('angle-normals');
const glsl = require('glslify');
const camera = require('regl-camera')(regl, {
  distance: 100,
  phi: 0.3,
  theta: 1.3,
  center: [0, 5, 0],
});
const mat4 = require('gl-mat4');
const teapot = require('teapot');

function rotateAround(r) {
  let s = t = [0, 0, 0];
  if (r[0] < r[1] && r[0] < r[2]) {
    s = [0, -1.0 * r[2], r[1]];
  } else if (r[1] < r[0] && r[1] < r[2]) {
    s = [-1.0 * r[2], 0, r[0]];
  } else {
    s = [-1.0 * r[1], r[0], 0];
  }

  s /= Math.sqrt(s[0] * s[0] + s[1] * s[1] + s[2] * s[2]);

}

function getTransformation(tick) {
  let rotate = mat4.create();
  mat4.rotate(rotate, rotate, tick * 0.03, [1, 1, 0]);

  return rotate;
}

const drawScene = regl({
  frag: glsl.file('./frag.glsl'),
  vert: glsl.file('./vert.glsl'),
  attributes: {
    position: teapot.positions,
    normal: angleNormals(teapot.cells, teapot.positions),
  },
  uniforms: {
    lightDir: [0, 1, 0],
    transformation: regl.prop('transformation'),
    time: regl.context('time'),
  },
  elements: teapot.cells,
});

regl.frame(({tick}) => {
  regl.clear({
    color: [0, 0, 0, 1],
    depth: 1,
  });

  const transformation = getTransformation(tick);

  camera(() => {
    drawScene({transformation});
  });
});
