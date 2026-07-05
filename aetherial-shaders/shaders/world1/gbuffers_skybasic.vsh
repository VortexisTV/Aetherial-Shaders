#version 120
// End sky dome: deep void, no overworld gradient.
varying vec3 vViewDir;

void main() {
    gl_Position = ftransform();
    vViewDir = (gl_ModelViewMatrix * gl_Vertex).xyz;
}
