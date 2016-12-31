const regl = require('regl')();
const bunny = require('bunny');
const angleNormals = require('angle-normals');
const camera = require('regl-camera')(regl, {
  distance: 30,
  phi: 0.7,
  theta: 1.5,
  center: [0, 5, 0],
});

const drawBunny = regl({
  vert: `
  precision mediump float;
  attribute vec3 position, normal;
  uniform mat4 projection, view;
  varying vec3 color;
  uniform float time;
  uniform vec4 lightDir;
  uniform vec3 lightIntensity, ambientIntensity, lightColor;

  void main() {
    gl_Position = projection * view * vec4(position, 1);
    float incidence = dot(lightDir, view * vec4(normal, 0.0));
    color = vec3(0.5) * (incidence * lightIntensity * lightColor) +
      ambientIntensity * lightColor;
  }
  `,
  frag: `
  precision mediump float;
  varying vec3 color;
  void main() {
    gl_FragColor = vec4(color, 1.0);
  }
  `,
  attributes: {
    position: bunny.positions,
    normal: angleNormals(bunny.cells, bunny.positions),
  },
  uniforms: {
    lightDir: [0, 1, 0, 0],
    lightIntensity: [0.6, 0.6, 0.6],
    lightColor: [1.0, 1.0, 1.0],
    ambientIntensity: [0.4, 0.4, 0.4],
    time: regl.prop('time'),
  },
  elements: bunny.cells,
});

regl.frame(({time}) => {
  regl.clear({ color: [0.2, 0.4, 0.6, 1] });
  camera(() => {
    drawBunny({ time });
  });
});
