#version 120
varying vec2 texcoord;
varying vec4 vColor;

void main() {
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0.xy;
    vColor = gl_Color;
}
