const regl = require('regl')({
  extensions: [
    'webgl_draw_buffers',
    'oes_texture_float',
  ],
});
const bunny = require('bunny');
const dragon = require('stanford-dragon/3');

const near = 0.01;
const far = 250.0;
const camera = require('regl-camera')(regl, {
  distance: 50,
  phi: 0.7,
  theta: 1.5,
  center: [0, 1, 0],
  near, far,
});

const glsl = require('glslify');
const angleNormals = require('angle-normals');
const mat4 = require('gl-mat4');
const control = require('control-panel');

const FOCAL_LENGTH = 'Focal length';
const FOCUS_DISTANCE = 'Focus distance';
const F_STOP = 'F-stop';
const GROUND_COLOUR = 'Ground colour';
const controls = control([
  {
    type: 'range',
    label: FOCAL_LENGTH,
    min: 10,
    max: 200,
    initial: 50,
  },
  {
    type: 'range',
    label: FOCUS_DISTANCE,
    min: 1,
    max: 20,
    step: 0.1,
    initial: 10.0,
  },
  {
    type: 'range',
    label: F_STOP,
    min: 1.4,
    max: 16.0,
    step: 0.1,
    initial: 6.0,
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
let focalLengthUnf = 50.0;
let focusDistanceUnf = 10.0;
let fStopUnf = 6.0;
controls.on('input', (data) => {
  groundColourUnf = data[GROUND_COLOUR]
    .match(/\d+/g)
    .map((colour) => (colour / 255));
  focalLengthUnf = data[FOCAL_LENGTH];
  focusDistanceUnf = data[FOCUS_DISTANCE];
  fStopUnf = data[F_STOP];
});

const PI = 3.14159265;

function radians(degrees) {
  return degrees * PI / 180;
}

const fbo = regl.framebuffer({
  depth: true,
  color: [
    regl.texture({ type: 'float' }), // colour
    regl.texture({ type: 'float' }), // depth
    regl.texture({ type: 'float' }), // blur
  ],
});

const blurFBO = regl.framebuffer({
  color: regl.texture({ type: 'float' }),
});

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
    far: regl.prop('far'),
    near: regl.prop('near'),
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
  depth: {
    enable: true,
  },
  framebuffer: fbo,
});

const drawDragon = regl({
  vert: glsl.file('./passThrough.vert'),
  frag: glsl.file('./shade.frag'),
  attributes: {
    position: dragon.positions,
    normal: angleNormals(dragon.cells, dragon.positions),
  },
  uniforms: {
    far: regl.prop('far'),
    near: regl.prop('near'),
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
  depth: {
    enable: true,
  },
  framebuffer: fbo,
});

const drawBunny = regl({
  vert: glsl.file('./passThrough.vert'),
  frag: glsl.file('./shade.frag'),
  attributes: {
    position: bunny.positions,
    normal: angleNormals(bunny.cells, bunny.positions),
  },
  uniforms: {
    far: regl.prop('far'),
    near: regl.prop('near'),
    modelColour: [0.2, 0.3, 0.0],
    transformation: () => {
      const transform = mat4.create();
      mat4.translate(transform, transform, [0, 0, 8]);
      return transform;
    },
  },
  elements: bunny.cells,
  depth: {
    enable: true,
  },
  cull: {
    enable: true,
    face: 'back',
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
    albedo: fbo.color[0],
    depth: fbo.color[1],
    blur: blurFBO,
  },
  elements: [0, 3, 2, 0, 2, 1],
  depth: {
    enable: false,
  },
});

const drawBlur = regl({
  vert: glsl.file('./fullscreen.vert'),
  frag: glsl.file('./blur.frag'),
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
    blurCoefficient: regl.prop('blurCoefficient'),
    focusDistance: regl.prop('focusDistance'),
    near: regl.prop('near'),
    far: regl.prop('far'),
    ppm: regl.prop('ppm'),
    orientation: regl.prop('orientation'),
    texelSize: regl.prop('texelSize'),
    albedo: () => {
      // If it's the first pass, set input tex to albedo.
      // Otherwise, set it to the half-burred blur tex.
      if (regl.prop('orientation' == 0)) {
        return fbo.color[0];
      }

      return blurFBO.color[0];
    },
    depthTex: fbo.color[1],
  },
  elements: [0, 3, 2, 0, 2, 1],
  depth: {
    enable: false,
  },
  framebuffer: () => {
    if (regl.prop('orientation' == 0)) {
      return blurFBO;
    }

    return fbo;
  },
});


const getBlurCoefficient = (f, Ds, fStop) => {
  const Ms = f / (Ds - f);
  return f * Ms / fStop;
};

const getPPM = (width, height) => {
  /**
              /|
focalLength /  | height
          /ppm |
        /      |
      ----------
      width
  */

  return Math.sqrt(width * width + height * height);
};

regl.frame(({viewportWidth, viewportHeight}) => {
  fbo.resize(viewportWidth, viewportHeight);

  const texelSize = [
    1 / viewportWidth,
    1 / viewportHeight,
  ];

  const blurCoefficient = getBlurCoefficient(focalLengthUnf,
    focusDistanceUnf, fStopUnf);

  const ppm = getPPM(viewportWidth, viewportHeight);

  camera(() => {
    regl.clear({
      color: [0,0,0,1],
      depth: 1,
      framebuffer: fbo,
    });

    drawFloor({groundColourUnf, near, far});
    drawBunny({near, far});
    drawDragon({near, far});

    drawBlur({
      orientation: 0,
      near, far,
      texelSize,
      focusDistance: focusDistanceUnf,
      blurCoefficient,
      ppm,
    });

    drawBlur({
      orientation: 1,
      near, far,
      texelSize,
      focusDistance: focusDistanceUnf,
      blurCoefficient,
      ppm,
    });

    postProcess();
  });
});
