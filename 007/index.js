const regl = require('regl')();
const angleNormals = require('angle-normals');
const glsl = require('glslify');
const mat4 = require('gl-mat4');
const teapot = require('teapot');

const drawScene = regl({
  frag: glsl.file('./frag.glsl'),
  vert: glsl.file('./vert.glsl'),
  attributes: {
    position: teapot.positions,
    normal: angleNormals(teapot.cells, teapot.positions),
  },
  uniforms: {
    'lights[0].position': [0, 100, 0],
    'lights[0].colour': [1, 1, 1],
    'lights[0].intensity': 0.4,
    'lights[1].position': ({tick}) => [
      Math.cos(tick * 0.05) * 100,
      Math.sin(tick * 0.05) * 100,
      Math.cos(tick * 0.05) * 100,
    ],
    'lights[1].colour': [0.2, 0.4, 0.6],
    'lights[1].intensity': 0.75,
    projection: ({viewportWidth, viewportHeight}) => {
      return mat4.perspective([], Math.PI / 4,
                              viewportWidth / viewportHeight,
                              0.01, 1000);
    },
    transformation: regl.prop('transformation'),
    time: regl.context('time'),
    view: mat4.translate([], mat4.create(), [0, 0, -100]),
  },
  elements: teapot.cells,
});

regl.frame(({tick}) => {
  regl.clear({
    color: [0, 0, 0, 1],
    depth: 1,
  });

  const transformation = mat4.rotate([], mat4.create(),
                                     tick * 0.03, [1, 1, 0]);
  drawScene({transformation});
});
