// Shared math + encoding helpers. Included by nearly every program.
#ifndef COMMON_GLSL
#define COMMON_GLSL

#include "/settings.glsl"

const float PI  = 3.14159265359;
const float TAU = 6.28318530718;

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

float sqr(float x) { return x * x; }
vec3  sqr(vec3 x)  { return x * x; }

// -- Ordered (Bayer) dithering, float-only so GLSL 120 is happy --
float bayer2(vec2 a) { a = floor(a); return fract(a.x * 0.5 + a.y * a.y * 0.75); }
#define bayer4(a)  (bayer2(0.5 * (a)) * 0.25 + bayer2(a))
#define bayer8(a)  (bayer4(0.5 * (a)) * 0.25 + bayer2(a))
#define bayer16(a) (bayer8(0.5 * (a)) * 0.25 + bayer2(a))

// -- colortex3 material data ------------------------------------
// rg: view-space normal xy (0..1)   b: reflectance mask   a: written flag
// mask: 0 = none, ~0.25 = wet puddle, ~0.5 = generic translucent, 1.0 = water
vec4 encodeGData(vec3 viewNormal, float mask) {
    return vec4(viewNormal.xy * 0.5 + 0.5, mask, 1.0);
}
vec3 decodeGNormal(vec4 data) {
    vec2 n = data.rg * 2.0 - 1.0;
    return vec3(n, sqrt(max(1.0 - dot(n, n), 0.0)));
}

// -- projection helpers (need gbufferProjection[Inverse] declared) ---
vec3 screenToView(vec3 screenPos, mat4 projInv) {
    vec4 ndc = vec4(screenPos * 2.0 - 1.0, 1.0);
    vec4 v = projInv * ndc;
    return v.xyz / v.w;
}
vec3 viewToScreen(vec3 viewPos, mat4 proj) {
    vec4 clip = proj * vec4(viewPos, 1.0);
    return clip.xyz / clip.w * 0.5 + 0.5;
}

float linearDepth(float depth, float near, float far) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

#endif
