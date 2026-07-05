#version 120
/* DRAWBUFFERS:0 */
#include "/lib/common.glsl"

uniform sampler2D texture;
uniform float rainStrength;

varying vec2 texcoord;
varying vec4 vColor;
varying float vIsSun;

void main() {
    vec4 tex = texture2D(texture, texcoord) * vColor;

    // HDR-boost the celestial bodies so bloom picks them up
    vec3 col = tex.rgb;
    col *= mix(vec3(1.1, 1.25, 1.6) * 1.8,     // moon: cool and gentle
               vec3(1.35, 1.05, 0.75) * 5.0,   // sun: warm and hot
               vIsSun);
    col *= 1.0 - rainStrength * 0.85;

    gl_FragData[0] = vec4(col, tex.a);
}
