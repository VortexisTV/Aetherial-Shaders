#version 120
// Lines, leashes, block selection outline.
varying vec4 vColor;

void main() {
    gl_Position = ftransform();
    vColor = gl_Color;
}
