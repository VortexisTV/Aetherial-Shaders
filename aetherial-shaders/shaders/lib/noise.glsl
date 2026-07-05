// Hash / value noise / fbm used by clouds, water, caustics, puddles, stars.
#ifndef NOISE_GLSL
#define NOISE_GLSL

float hash12(vec2 p) {
    p = fract(p * vec2(443.897, 441.423));
    p += dot(p, p.yx + 19.19);
    return fract((p.x + p.y) * p.x);
}

float noise2(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash12(i);
    float b = hash12(i + vec2(1.0, 0.0));
    float c = hash12(i + vec2(0.0, 1.0));
    float d = hash12(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// fbm with a wind offset per octave; octaves must be a compile-time-ish small int
float fbm(vec2 p, int octaves, vec2 wind) {
    float sum = 0.0;
    float amp = 0.5;
    for (int i = 0; i < 6; i++) {
        if (i >= octaves) break;
        sum += noise2(p + wind * float(i + 1)) * amp;
        p = p * 2.13 + vec2(37.0, 17.0);
        amp *= 0.5;
    }
    return sum;
}

// Cheap animated caustic pattern (two scrolling noise layers, sharpened)
float caustic(vec2 p, float t) {
    float n1 = noise2(p * 1.7 + vec2(t * 0.30, t * 0.21));
    float n2 = noise2(p * 2.3 - vec2(t * 0.26, t * 0.35));
    float c = 1.0 - abs(n1 - n2) * 2.0;
    return pow(max(c, 0.0), 4.0);
}

#endif
