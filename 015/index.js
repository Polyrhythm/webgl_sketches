const regl = require('regl')();
const bunny = require('bunny');
const dragon = require('stanford-dragon/3');
const camera = require('regl-camera')(regl, {
  distance: 50,
  phi: 0.7,
  theta: 1.5,
  center: [0, 1, 0],
});
const glsl = require('glslify');
const angleNormals = require('angle-normals');
const mat4 = require('gl-mat4');
const control = require('control-panel');

const APERTURE = 'Aperture';
const GROUND_COLOUR = 'Ground colour';
const controls = control([
  {
    type: 'range',
    label: APERTURE,
    min: 0,
    max: 5,
    initial: 1,
  },
  {
    type: 'color',
    label: GROUND_COLOUR,
    format: 'rgb',
    initial: 'rgb(25, 51, 76)',
  },
], {
  title: 'Depth of field',
});

let groundColourUnf = [0.1, 0.2, 0.3];
controls.on('input', (data) => {
  groundColourUnf = data[GROUND_COLOUR]
    .match(/\d+/g)
    .map((colour) => (colour / 255));
});

const PI = 3.14159265;

function radians(degrees) {
  return degrees * PI / 180;
}

const drawFloor = regl({
  vert: glsl.file('./passThrough.vert'),
  frag: glsl.file('./ground.frag'),
  attributes: {
    position: [
      -1, 0, +1,
      +1, 0, +1,
      +1, 0, -1,
      -1, 0, -1,
    ],
    normal: [
      0, 1, 0,
      0, 1, 0,
      0, 1, 0,
      0, 1, 0,
    ],
  },
  uniforms: {
    groundColourUnf: regl.prop('groundColourUnf'),
    transformation: () => {
      const transform = mat4.create();
      mat4.scale(transform, transform, [20, 1, 20]);
      return transform;
    },
  },
  elements: [0, 1, 2, 0, 2, 3],
  cull: {
    enable: true,
    face: 'back',
  },
})

const drawDragon = regl({
  vert: glsl.file('./passThrough.vert'),
  frag: glsl.file('./shade.frag'),
  attributes: {
    position: dragon.positions,
    normal: angleNormals(dragon.cells, dragon.positions),
  },
  uniforms: {
    modelColour: [0.1, 0.0, 0.3],
    transformation: () => {
      const transform = mat4.create();
      mat4.translate(transform, transform, [-10.0, -4.0, -7.0]);
      mat4.rotateY(transform, transform, radians(45));
      mat4.scale(transform, transform, [0.15, 0.15, 0.15]);
      return transform;
    },
  },
  elements: dragon.cells,
  cull: {
    enable: true,
    face: 'back',
  },
});

const drawBunny = regl({
  vert: glsl.file('./passThrough.vert'),
  frag: glsl.file('./shade.frag'),
  attributes: {
    position: bunny.positions,
    normal: angleNormals(bunny.cells, bunny.positions),
  },
  uniforms: {
    modelColour: [0.2, 0.3, 0.0],
    transformation: () => {
      const transform = mat4.create();
      mat4.translate(transform, transform, [0, 0, 8]);
      return transform;
    },
  },
  elements: bunny.cells,
  cull: {
    enable: true,
    face: 'back',
  },
});

regl.frame(() => {
  regl.clear({
    color: [0, 0, 0, 1],
    depth: 1,
  });

  camera(() => {
    drawFloor({groundColourUnf});
    drawBunny();
    drawDragon();
  });
});
