// Water surface normal detail from layered animated noise.
#ifndef WATER_GLSL
#define WATER_GLSL

#include "/lib/common.glsl"
#include "/lib/noise.glsl"

float waterHeightDetail(vec2 p, float t) {
    float h = 0.0;
    h += sin(dot(p, vec2(0.86, 0.29)) * 1.9 + t * 1.9) * 0.45;
    h += sin(dot(p, vec2(-0.41, 0.74)) * 2.6 + t * 1.4) * 0.30;
    h += noise2(p * 0.9 + vec2(t * 0.22, t * 0.17)) * 0.55;
    h += noise2(p * 2.3 - vec2(t * 0.31, t * 0.09)) * 0.25;
    return h;
}

// world-space normal for a mostly-horizontal water surface
vec3 waterNormal(vec2 absXZ, float t, float strength) {
    const float e = 0.08;
    float h0 = waterHeightDetail(absXZ, t);
    float hx = waterHeightDetail(absXZ + vec2(e, 0.0), t);
    float hz = waterHeightDetail(absXZ + vec2(0.0, e), t);
    vec2 grad = vec2(hx - h0, hz - h0) / e * 0.055 * strength;
    return normalize(vec3(-grad.x, 1.0, -grad.y));
}

#endif
