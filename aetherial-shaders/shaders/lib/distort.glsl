// Shadow-map distortion: spends more texels near the player.
// MUST stay identical between shadow.vsh and lib/shadows.glsl sampling.
#ifndef DISTORT_GLSL
#define DISTORT_GLSL

float shadowDistortFactor(vec2 clipXY) {
    return length(clipXY) * 0.9 + 0.1;
}

vec3 distortShadowClip(vec3 clipPos) {
    float f = shadowDistortFactor(clipPos.xy);
    return vec3(clipPos.xy / f, clipPos.z * 0.5);
}

#endif
