#version 120
/* DRAWBUFFERS:2 */
// Bloom: vertical gaussian to finish the blur.
#include "/lib/common.glsl"

uniform sampler2D colortex2;
uniform float viewHeight;

varying vec2 texcoord;

void main() {
    #ifdef BLOOM
    float px = 1.0 / viewHeight;
    vec3 bloom = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = exp(-float(i * i) * 0.08);
        bloom += texture2D(colortex2, texcoord + vec2(0.0, float(i) * px * 3.0)).rgb * w;
        wsum += w;
    }
    gl_FragData[0] = vec4(bloom / wsum, 1.0);
    #else
    gl_FragData[0] = vec4(0.0);
    #endif
}
