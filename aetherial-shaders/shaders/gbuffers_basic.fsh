#version 120
/* DRAWBUFFERS:0 */
varying vec4 vColor;

void main() {
    gl_FragData[0] = vColor;
}
