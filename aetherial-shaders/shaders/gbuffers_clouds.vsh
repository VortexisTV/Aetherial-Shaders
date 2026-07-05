#version 120
// Vanilla clouds. Hidden entirely while volumetric clouds are enabled.
varying vec2 texcoord;
varying vec4 vColor;

void main() {
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0.xy;
    vColor = gl_Color;
}
