// Vertex wind / wave displacement. Used identically by the gbuffers
// AND the shadow pass so shadows follow the swaying geometry.
// worldPos here is player-relative world position (before cameraPosition add).
#ifndef WAVE_GLSL
#define WAVE_GLSL

#include "/lib/common.glsl"

vec3 windOffset(vec3 absWorldPos, float t, float strength) {
    float phase = dot(absWorldPos.xz, vec2(0.5, 0.8));
    float gust  = sin(t * 0.7 + phase * 0.15) * 0.5 + 0.5;
    float sway  = sin(t * 1.6 + phase) + sin(t * 2.7 + phase * 1.7) * 0.5;
    float lift  = cos(t * 1.9 + phase * 1.3) * 0.5;
    return vec3(sway, lift * 0.3, sway * 0.6) * 0.025 * strength * (0.4 + 0.6 * gust);
}

// blockId groups from block.properties; topVertex = 1.0 for upper quad verts
vec3 vegetationWave(float blockId, vec3 absWorldPos, float topVertex, float t, float rain) {
    float strength = 1.0 + rain * 1.5;
    vec3 off = vec3(0.0);

    #ifdef WAVING_PLANTS
    if (blockId > 10000.5 && blockId < 10001.5)       // ground plants: base anchored
        off = windOffset(absWorldPos, t, strength) * topVertex;
    else if (blockId > 10001.5 && blockId < 10002.5)  // tall plants / vines
        off = windOffset(absWorldPos, t, strength * 0.8) * (0.35 + 0.65 * topVertex);
    else if (blockId > 10015.5 && blockId < 10016.5)  // lily pads bob
        off = vec3(0.0, sin(t * 2.0 + dot(absWorldPos.xz, vec2(0.7, 1.1))) * 0.012, 0.0);
    #endif

    #ifdef WAVING_LEAVES
    if (blockId > 10002.5 && blockId < 10003.5)       // leaves: whole block soft motion
        off = windOffset(absWorldPos * 0.5, t, strength * 0.7);
    #endif

    return off;
}

// water surface vertex waves
float waterWaveHeight(vec2 absXZ, float t) {
    #ifdef WATER_WAVES
    float h = sin(dot(absXZ, vec2(0.32, 0.51)) + t * 1.7)
            + sin(dot(absXZ, vec2(-0.47, 0.29)) + t * 1.3) * 0.7
            + sin(dot(absXZ, vec2(0.12, -0.61)) + t * 2.3) * 0.4;
    return h * 0.018 * WATER_WAVE_HEIGHT;
    #else
    return 0.0;
    #endif
}

#endif
