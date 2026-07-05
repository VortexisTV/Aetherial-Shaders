// ACES tonemap + filmic fantasy color grade.
#ifndef TONEMAP_GLSL
#define TONEMAP_GLSL

#include "/lib/common.glsl"

vec3 acesFilm(vec3 x) {
    const float a = 2.51, b = 0.03, c = 2.43, d = 0.59, e = 0.14;
    return clamp((x * (a * x + b)) / (x * (c * x + d) + e), 0.0, 1.0);
}

// applied AFTER tonemap, in display space
vec3 colorGrade(vec3 c) {
    #ifdef COLOR_GRADING
    // white balance
    float temp = TEMPERATURE;
    c *= mix(vec3(1.0), temp > 0.0 ? vec3(1.10, 1.00, 0.85) : vec3(0.88, 0.97, 1.12), abs(temp) * 0.6);

    // gentle fantasy split-tone: cool shadows, warm highlights
    float l = luma(c);
    c += (vec3(0.02, 0.015, 0.05) * (1.0 - l) - vec3(0.0, 0.005, 0.02) * l) * 0.5;

    // vibrance boosts muted colors more than saturated ones
    float satNow = max(max(c.r, c.g), c.b) - min(min(c.r, c.g), c.b);
    float vib = (VIBRANCE - 1.0) * (1.0 - satNow);
    c = mix(vec3(luma(c)), c, 1.0 + vib);

    // plain saturation + contrast around mid gray
    c = mix(vec3(luma(c)), c, SATURATION);
    c = (c - 0.5) * CONTRAST + 0.5;
    #endif
    return clamp(c, 0.0, 1.0);
}

#endif
