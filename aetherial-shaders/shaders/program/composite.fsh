// Main atmosphere pass: SSAO, volumetric clouds, caustics, fog, god rays.
// Wrapper defines one of: OVERWORLD_DIM / NETHER_DIM / END_DIM.
#include "/lib/common.glsl"
#include "/lib/sky.glsl"
#include "/lib/shadows.glsl"
#include "/lib/noise.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float blindness;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;
uniform vec3 fogColor;

varying vec2 texcoord;

// --- shadow visibility for the volumetric march (single tap, dithered) ---
float vlShadowSample(vec3 relPos) {
    vec4 clip = shadowProjection * (shadowModelView * vec4(relPos, 1.0));
    vec3 sp = distortShadowClip(clip.xyz) * 0.5 + 0.5;
    if (clamp(sp.xy, 0.0, 1.0) != sp.xy || sp.z >= 1.0) return 1.0;
    return shadowSample(sp.xy, sp.z - 0.0008);
}

// --- SSAO from depth + gbuffer normals -----------------------------------
#ifdef SSAO
float computeSSAO(vec3 viewPos, vec3 normalV, float dither) {
    #if SSAO_QUALITY == 1
    const int TAPS = 6;
    #elif SSAO_QUALITY == 2
    const int TAPS = 10;
    #else
    const int TAPS = 16;
    #endif

    float radius = 0.55;
    float occlusion = 0.0;
    float rot = dither * TAU;

    for (int i = 0; i < TAPS; i++) {
        float fi = float(i);
        float ang = rot + fi * 2.39996;                    // golden angle spiral
        float r = radius * (fi + 0.5) / float(TAPS);
        vec3 offset = vec3(cos(ang), sin(ang), 0.6) * r;
        offset *= sign(dot(offset, normalV) + 0.2);        // hemisphere-ish

        vec3 samplePos = viewPos + offset;
        vec3 sampleScreen = viewToScreen(samplePos, gbufferProjection);
        if (clamp(sampleScreen.xy, 0.0, 1.0) != sampleScreen.xy) continue;

        float sampleDepth = texture2D(depthtex0, sampleScreen.xy).r;
        vec3 actual = screenToView(vec3(sampleScreen.xy, sampleDepth), gbufferProjectionInverse);
        float diff = actual.z - samplePos.z;               // positive: blocker in front
        float range = smoothstep(0.0, 1.0, radius / max(abs(viewPos.z - actual.z), 0.001));
        occlusion += step(0.02, diff) * range;
    }
    occlusion /= float(TAPS);
    return clamp(1.0 - occlusion * 0.85, 0.0, 1.0);
}
#endif

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    float depth0 = texture2D(depthtex0, texcoord).r;
    float depth1 = texture2D(depthtex1, texcoord).r;

    vec3 viewPos = screenToView(vec3(texcoord, depth0), gbufferProjectionInverse);
    vec3 relPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
    float dist = length(relPos);
    vec3 dirW = relPos / max(dist, 1e-5);

    vec3 sunW = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 lightW = normalize(mat3(gbufferModelViewInverse) * shadowLightPosition);
    float dither = bayer16(gl_FragCoord.xy);
    bool isSky = depth0 >= 1.0;

    vec4 gdata = texture2D(colortex3, texcoord);
    float eyeSky = float(eyeBrightnessSmooth.y) / 240.0;

// ==================== OVERWORLD ====================
#ifdef OVERWORLD_DIM
    vec3 sunCol = aetherialSunColor(sunW.y);

    if (!isSky) {
        // ---- ambient occlusion ----
        #ifdef SSAO
        if (gdata.a > 0.5) {
            vec3 normalV = decodeGNormal(gdata);
            float ao = computeSSAO(viewPos, normalV, dither);
            color *= mix(1.0, ao, 0.9);
        }
        #endif

        // ---- caustics on submerged surfaces ----
        #ifdef WATER_CAUSTICS
        bool floorUnderWater = gdata.b > 0.9 && depth1 > depth0;
        if ((isEyeInWater == 1 || floorUnderWater) && depth1 < 1.0) {
            vec3 viewPos1 = screenToView(vec3(texcoord, depth1), gbufferProjectionInverse);
            vec3 relPos1 = (gbufferModelViewInverse * vec4(viewPos1, 1.0)).xyz;
            vec3 absPos1 = relPos1 + cameraPosition;
            float c = caustic(absPos1.xz * 0.55, frameTimeCounter);
            float gate = isEyeInWater == 1 ? eyeSky : 1.0;
            color *= 1.0 + c * 0.55 * gate * luma(sunCol) * 0.35;
        }
        #endif
    }

    // ---- volumetric cloud deck ----
    #ifdef VOLUMETRIC_CLOUDS
    if (isEyeInWater == 0) {
        float maxDist = isSky ? 1e9 : dist;
        vec4 cl = cloudLayer(cameraPosition, dirW, sunW, rainStrength,
                             frameTimeCounter, dither, maxDist);
        color = mix(color, cl.rgb, cl.a);
    }
    #endif

    // ---- fog ----
    if (isEyeInWater == 1) {
        vec3 waterFog = vec3(0.04, 0.22, 0.40) * (0.15 + 0.85 * eyeSky)
                      * (0.3 + 0.7 * clamp(sunW.y + 0.4, 0.0, 1.0));
        float fogAmount = 1.0 - exp(-dist * 0.055 * FOG_DENSITY);
        color = mix(color, waterFog, clamp(fogAmount, 0.0, 1.0));
    } else if (!isSky) {
        vec3 absPos = relPos + cameraPosition;
        float heightBoost = clamp((72.0 - absPos.y) * 0.012, 0.0, 0.8);
        float duskMist = 1.0 - smoothstep(0.05, 0.30, abs(sunW.y));
        float density = FOG_DENSITY * (0.0011 + rainStrength * 0.0040
                       + heightBoost * 0.0012 + duskMist * 0.0009);
        float fogAmount = 1.0 - exp(-dist * density);
        vec3 fogC = fogColorFor(dirW, sunW, rainStrength);
        color = mix(color, fogC, clamp(fogAmount, 0.0, 1.0));
    }

    // ---- god rays / volumetric light ----
    #ifdef GODRAYS
    {
        float cosT = dot(dirW, lightW);
        const float g = 0.55;
        float phase = (1.0 - g * g) / (4.0 * PI * pow(1.0 + g * g - 2.0 * g * cosT, 1.5));

        float rayEnd = min(dist, shadowDistance * 0.9);
        float stepLen = rayEnd / float(VL_SAMPLES);
        float lit = 0.0;
        for (int i = 0; i < VL_SAMPLES; i++) {
            float t = (float(i) + dither) * stepLen;
            lit += vlShadowSample(dirW * t);
        }
        lit /= float(VL_SAMPLES);

        float duskBoost = 1.0 + (1.0 - smoothstep(0.05, 0.35, abs(sunW.y))) * 1.6;
        if (isEyeInWater == 1) {
            vec3 shaft = sunCol * vec3(0.25, 0.60, 0.80);
            color += shaft * lit * phase * 1.6 * VL_STRENGTH * eyeSky;
        } else {
            float density = 0.35 + rainStrength * 0.5;
            color += sunCol * lit * phase * density * duskBoost * VL_STRENGTH
                   * (0.25 + 0.75 * eyeSky);
        }
    }
    #endif
#endif

// ==================== NETHER ====================
#ifdef NETHER_DIM
    if (!isSky) {
        #ifdef SSAO
        if (gdata.a > 0.5) {
            vec3 normalV = decodeGNormal(gdata);
            color *= mix(1.0, computeSSAO(viewPos, normalV, dither), 0.75);
        }
        #endif
    }
    // biome-aware fog (crimson / warped / soul valley differ) pushed toward embers
    vec3 netherFog = mix(vec3(0.30, 0.07, 0.02), fogColor * 1.15, 0.55);
    float fogAmount = 1.0 - exp(-dist * 0.014 * FOG_DENSITY);
    color = mix(color, netherFog, clamp(fogAmount, 0.0, 1.0) * (isSky ? 1.0 : 0.92));
    if (isSky) color = netherFog * 1.05;
    // faint ember shimmer in the air
    color += vec3(0.25, 0.06, 0.01) * noise2(texcoord * 6.0 + frameTimeCounter * 0.15)
           * 0.03 * FOG_DENSITY;
#endif

// ==================== END ====================
#ifdef END_DIM
    if (!isSky) {
        #ifdef SSAO
        if (gdata.a > 0.5) {
            vec3 normalV = decodeGNormal(gdata);
            color *= mix(1.0, computeSSAO(viewPos, normalV, dither), 0.85);
        }
        #endif
        vec3 endFog = vec3(0.09, 0.05, 0.15);
        float fogAmount = 1.0 - exp(-dist * 0.006 * FOG_DENSITY);
        color = mix(color, endFog, clamp(fogAmount, 0.0, 1.0));
    } else {
        // eerie void: purple glow near the horizon, darkness above and below
        float horizonGlow = pow(1.0 - abs(dirW.y), 4.0);
        color = color * 0.8 + vec3(0.16, 0.08, 0.26) * horizonGlow * 0.7;
        color += vec3(0.05, 0.02, 0.09) * noise2(dirW.xz * 4.0 + frameTimeCounter * 0.02);
    }
#endif

    // blindness closes in everywhere
    color = mix(color, vec3(0.0), clamp(blindness * dist * 0.2, 0.0, 1.0));

    gl_FragData[0] = vec4(color, 1.0);
}
