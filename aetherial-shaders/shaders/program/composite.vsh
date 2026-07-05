// Fullscreen pass vertex stage shared by all composite/final programs.
varying vec2 texcoord;

void main() {
    gl_Position = ftransform();
    texcoord = gl_MultiTexCoord0.xy;
}
