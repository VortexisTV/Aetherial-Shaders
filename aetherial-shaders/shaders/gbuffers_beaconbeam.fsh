#version 120
/* DRAWBUFFERS:0 */
#include "/lib/common.glsl"

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 vColor;

void main() {
    vec4 tex = texture2D(texture, texcoord) * vColor;
    // fully emissive so it blooms
    gl_FragData[0] = vec4(tex.rgb * (1.5 + 1.5 * EMISSIVE_STRENGTH), tex.a);
}
