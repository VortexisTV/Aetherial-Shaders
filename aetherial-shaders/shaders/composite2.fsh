#version 120
/* DRAWBUFFERS:2 */
// Bloom: bright-pass on a low mip of the scene + horizontal gaussian.
#include "/lib/common.glsl"

const bool colortex0MipmapEnabled = true;

uniform sampler2D colortex0;
uniform float viewWidth;

varying vec2 texcoord;

vec3 brightPass(vec2 uv) {
    #ifdef BLOOM
    vec3 c = texture2D(colortex0, uv, 2.0).rgb;      // lod bias -> pre-blurred mip
    float l = luma(c);
    // threshold above typical sunlit ground so only emissives, sun,
    // specular glints and the brightest sky bloom out
    return c * smoothstep(1.6, 3.2, l);
    #else
    return vec3(0.0);
    #endif
}

void main() {
    #ifdef BLOOM
    float px = 1.0 / viewWidth;
    vec3 bloom = vec3(0.0);
    float wsum = 0.0;
    for (int i = -6; i <= 6; i++) {
        float w = exp(-float(i * i) * 0.08);
        bloom += brightPass(texcoord + vec2(float(i) * px * 3.0, 0.0)) * w;
        wsum += w;
    }
    gl_FragData[0] = vec4(bloom / wsum, 1.0);
    #else
    gl_FragData[0] = vec4(0.0);
    #endif
}
