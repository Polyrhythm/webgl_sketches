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
  uniform vec4 lightDir;
  uniform vec3 lightIntensity,lightColor, ambientIntensity, ambientColor,
    specularColor;
  uniform float shininess;
  varying vec3 colour;

  void main() {
    vec4 viewPos = view * vec4(position, 1.0);
    vec4 normCamSpace = normalize(view * vec4(normal, 0.0));
    vec3 diffuseColour = vec3(1.0);
    gl_Position = projection * viewPos;

    vec4 viewDir = normalize(-viewPos);
    vec4 reflectDir = reflect(-lightDir, normCamSpace);

    float incidence = dot(normCamSpace, lightDir);
    incidence = clamp(incidence, 0.0, 1.0);

    float phongTerm = dot(viewDir, reflectDir);
    phongTerm = clamp(phongTerm, 0.0, 1.0);
    phongTerm = incidence != 0.0 ? phongTerm : 0.0;
    phongTerm = pow(phongTerm, shininess);

    vec3 diffuseLighting = incidence * lightIntensity * lightColor;
    vec3 ambientLighting = ambientIntensity * ambientColor;
    vec3 specularLighting = specularColor * phongTerm;

    colour = diffuseColour * diffuseLighting +
      specularLighting +
      ambientLighting;
  }
  `,

  frag: `
  precision mediump float;
  varying vec3 colour;
  varying vec4 normCamSpace;

  void main() {
    gl_FragColor = vec4(colour, 1.0);
  }
  `,

  attributes: {
    position: bunny.positions,
    normal: angleNormals(bunny.cells, bunny.positions),
  },
  uniforms: {
    lightDir: [0, 1, 0, 0],
    lightIntensity: [0.4, 0.4, 0.4],
    lightColor: [1, 1, 1],
    ambientIntensity: [0.2, 0.2, 0.2],
    ambientColor: [1.0, 1.0, 1.0],
    shininess: 6.0,
    specularColor: [0.5, 0.5, 0.5],
  },
  elements: bunny.cells
});

regl.frame(({ time }) => {
  regl.clear({ color: [0.2, 0.4, 0.6, 1] });
  camera(() => {
    drawBunny();
  });
});
