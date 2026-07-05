#version 120
// Vanilla sky dome geometry; the fragment stage repaints it procedurally.
varying vec3 vViewDir;

void main() {
    gl_Position = ftransform();
    vViewDir = (gl_ModelViewMatrix * gl_Vertex).xyz;
}
