#version 120
// Sun and moon quads (also the End sky texture).
uniform vec3 sunPosition;

varying vec2 texcoord;
varying vec4 vColor;
varying float vIsSun;

void main() {
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0.xy;
    vColor = gl_Color;

    vec3 viewDir = normalize((gl_ModelViewMatrix * gl_Vertex).xyz);
    vIsSun = step(0.75, dot(viewDir, normalize(sunPosition)));
}
