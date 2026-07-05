// Shadow map sampling with distortion-aware bias and rotated PCF.
// Uses shadowtex1 (opaque casters only) so sunlight passes through
// water/glass and underwater light shafts stay bright.
#ifndef SHADOWS_GLSL
#define SHADOWS_GLSL

#include "/lib/common.glsl"
#include "/lib/distort.glsl"

uniform sampler2D shadowtex1;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

float shadowSample(vec2 uv, float refZ) {
    return step(refZ, texture2D(shadowtex1, uv).r);
}

// relPos: player-relative world position. Returns 1 = fully lit.
float getShadow(vec3 relPos, vec3 normalW, float NdotL, float dither) {
    #ifndef SHADOWS
    return 1.0;
    #else
    float distXZ = length(relPos.xz);
    float fade = smoothstep(shadowDistance * 0.85, shadowDistance, distXZ);
    if (fade >= 1.0) return 1.0;

    // normal offset pushes the sample off the surface to kill acne
    float texelWorld = 2048.0 / float(shadowMapResolution);
    vec3 offPos = relPos + normalW * (0.03 + 0.05 * (1.0 - NdotL)) * texelWorld;

    vec4 shadowClip = shadowProjection * (shadowModelView * vec4(offPos, 1.0));
    float distortF = shadowDistortFactor(shadowClip.xy);
    vec3 shadowPos = distortShadowClip(shadowClip.xyz) * 0.5 + 0.5;
    if (shadowPos.z >= 1.0) return 1.0;

    float bias = (0.00012 + 0.0006 * distortF * distortF) * (2048.0 / float(shadowMapResolution));
    float refZ = shadowPos.z - bias;

    float radius = SHADOW_SOFTNESS * distortF * (1.2 / float(shadowMapResolution));

    float shade;
    #if SHADOW_PCF == 0
        shade = shadowSample(shadowPos.xy, refZ);
    #elif SHADOW_PCF == 1
        float a = dither * TAU;
        vec2 j = vec2(cos(a), sin(a)) * radius;
        shade = (shadowSample(shadowPos.xy + j, refZ)
               + shadowSample(shadowPos.xy - j, refZ)) * 0.5;
    #else
        #if SHADOW_PCF == 2
            const int TAPS = 4;
        #else
            const int TAPS = 9;
        #endif
        shade = 0.0;
        float rot = dither * TAU;
        for (int i = 0; i < TAPS; i++) {
            float ang = rot + float(i) * (TAU / float(TAPS));
            float r = radius * (0.4 + 0.6 * fract(float(i) * 0.618 + dither));
            shade += shadowSample(shadowPos.xy + vec2(cos(ang), sin(ang)) * r * (1.0 + float(i) * 0.35), refZ);
        }
        shade /= float(TAPS);
    #endif

    return mix(shade, 1.0, fade);
    #endif
}

#endif
