// Forward lighting shared by terrain, water, entities, block entities,
// hand and particles. Keeps vanilla's readable look, adds directional
// sun/moon light, warm blocklight, ambient floor and emissive boosts.
#ifndef LIGHTING_GLSL
#define LIGHTING_GLSL

#include "/lib/common.glsl"
#include "/lib/sky.glsl"
#include "/lib/shadows.glsl"

uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform mat4 gbufferModelViewInverse;
uniform float rainStrength;
uniform float nightVision;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

vec3 lightDirWorld()  { return normalize(mat3(gbufferModelViewInverse) * shadowLightPosition); }
vec3 sunDirWorld()    { return normalize(mat3(gbufferModelViewInverse) * sunPosition); }

const vec3 BLOCKLIGHT_COLOR = vec3(1.00, 0.56, 0.28);

// GGX-ish cheap specular for wet ground / water sun glints
float specHighlight(vec3 N, vec3 V, vec3 L, float roughness) {
    vec3 H = normalize(V + L);
    float NdotH = max(dot(N, H), 0.0);
    float p = mix(400.0, 24.0, roughness);
    return pow(NdotH, p) * (p + 8.0) * 0.125 * 0.25;
}

// relPos: player-relative world pos; normalW: world normal;
// lm: vanilla lightmap; subsurface: 1 for foliage; emissive: 0..n
// sunVis returns shadow*diffuse so callers can add specular highlights.
vec3 doLighting(vec3 albedo, vec3 relPos, vec3 normalW, vec2 lm,
                float subsurface, float emissive, float dither,
                out float sunVis) {
    vec3 L = lightDirWorld();
    float sunH = sunDirWorld().y;
    float rain = rainStrength;

    float NdotL = dot(normalW, L);
    float diffuse = clamp((NdotL + 0.15) / 1.15, 0.0, 1.0);          // soft wrap
    diffuse = mix(diffuse, 0.55 + 0.45 * abs(NdotL), subsurface);    // leaves translucency

    float shadow = 1.0;
    #ifdef END_DIM
    // The End: fixed pale light, still uses the shadow map
    if (diffuse > 0.001) shadow = getShadow(relPos, normalW, max(NdotL, 0.0), dither);
    vec3 keyCol = vec3(0.72, 0.58, 0.90) * 1.1;
    vec3 ambient = vec3(0.36, 0.28, 0.52) * 0.55;
    #else
    float skyGate = smoothstep(0.45, 0.95, lm.y);
    if (diffuse * skyGate > 0.001) shadow = getShadow(relPos, normalW, max(NdotL, 0.0), dither);
    vec3 keyCol = aetherialSunColor(sunH) * (1.0 - rain * 0.85);
    vec3 ambient = skyAmbientColor(sunH, rain);
    diffuse *= skyGate;
    #endif

    sunVis = diffuse * shadow;

    // sky ambient scales with skylight access
    float skyAmb = pow(lm.y, 2.2);
    vec3 light = ambient * skyAmb * (0.45 + 0.30 * clamp(normalW.y, 0.0, 1.0) + 0.25);

    // key light
    light += keyCol * diffuse * shadow;

    // blocklight: warm, slightly HDR near sources
    float bl = pow(lm.x, 2.0) * 1.5 + pow(lm.x, 6.0) * 1.6;
    light += BLOCKLIGHT_COLOR * bl;

    // held light source
    #ifdef HANDLIGHT
    float held = float(max(heldBlockLightValue, heldBlockLightValue2));
    if (held > 0.5) {
        float hl = clamp(held / 15.0 - length(relPos) / 12.0, 0.0, 1.0);
        light += BLOCKLIGHT_COLOR * hl * hl * 1.4;
    }
    #endif

    // ambient floor + night vision
    light = max(light, vec3(0.030, 0.034, 0.042) * MIN_LIGHT * (1.0 + nightVision * 14.0));

    vec3 col = albedo * light;

    // emissive: brightness of the texture drives the glow
    if (emissive > 0.001) {
        float e = pow(luma(albedo), 1.6) * emissive * EMISSIVE_STRENGTH;
        col += albedo * e;
    }
    return col;
}

#endif
