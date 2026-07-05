#version 120
/* DRAWBUFFERS:0 */
// The End void: near-black with a faint violet breath. The composite
// pass layers the horizon glow on top.
#include "/lib/common.glsl"

uniform mat4 gbufferModelViewInverse;

varying vec3 vViewDir;

void main() {
    vec3 dirW = normalize(mat3(gbufferModelViewInverse) * vViewDir);
    float horizon = pow(1.0 - abs(dirW.y), 3.0);
    vec3 col = vec3(0.012, 0.008, 0.022) + vec3(0.05, 0.025, 0.09) * horizon;
    gl_FragData[0] = vec4(col, 1.0);
}
