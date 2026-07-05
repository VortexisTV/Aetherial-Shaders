#version 120
/* DRAWBUFFERS:0 */
// Water refraction + screen-space ray-traced reflections (water & puddles).
#include "/lib/common.glsl"
#include "/lib/sky.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float rainStrength;
uniform float viewWidth;
uniform float viewHeight;
uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;

varying vec2 texcoord;

#if WATER_REFLECTIONS == 2
// coarse march + binary refine against depthtex0
vec4 traceSSR(vec3 viewPos, vec3 rayDir, float dither) {
    float rayLen = -viewPos.z * 1.8 + 16.0;
    vec3 pos = viewPos + rayDir * 0.05;
    float stepLen = rayLen / float(SSR_STEPS);
    vec3 stepVec = rayDir * stepLen;
    pos += stepVec * dither;

    for (int i = 0; i < SSR_STEPS; i++) {
        pos += stepVec;
        vec3 sp = viewToScreen(pos, gbufferProjection);
        if (clamp(sp.xy, 0.0, 1.0) != sp.xy || pos.z > 0.0) break;

        float d = texture2D(depthtex0, sp.xy).r;
        vec3 actual = screenToView(vec3(sp.xy, d), gbufferProjectionInverse);
        float diff = actual.z - pos.z;
        if (diff > 0.0 && diff < stepLen * 3.0 && d < 1.0) {
            // binary refinement
            vec3 lo = pos - stepVec, hi = pos;
            for (int j = 0; j < 4; j++) {
                vec3 mid = (lo + hi) * 0.5;
                vec3 msp = viewToScreen(mid, gbufferProjection);
                float md = texture2D(depthtex0, msp.xy).r;
                vec3 mact = screenToView(vec3(msp.xy, md), gbufferProjectionInverse);
                if (mact.z > mid.z) hi = mid; else lo = mid;
            }
            vec3 fsp = viewToScreen((lo + hi) * 0.5, gbufferProjection);
            vec2 border = abs(fsp.xy - 0.5) * 2.0;
            float edgeFade = 1.0 - smoothstep(0.75, 1.0, max(border.x, border.y));
            return vec4(texture2D(colortex0, fsp.xy).rgb, edgeFade);
        }
    }
    return vec4(0.0);
}
#endif

void main() {
    vec3 color = texture2D(colortex0, texcoord).rgb;
    float depth0 = texture2D(depthtex0, texcoord).r;
    vec4 gdata = texture2D(colortex3, texcoord);
    float mask = gdata.b;

    bool isWater = mask > 0.9;
    bool isGlass = mask > 0.5 && mask < 0.75;
    float puddle = (mask > 0.03 && mask < 0.45) ? mask : 0.0;

    if (depth0 < 1.0 && (isWater || isGlass || puddle > 0.0)) {
        vec3 viewPos = screenToView(vec3(texcoord, depth0), gbufferProjectionInverse);
        vec3 normalV = decodeGNormal(gdata);
        vec3 viewDir = normalize(viewPos);
        float dither = bayer16(gl_FragCoord.xy);
        float eyeSky = float(eyeBrightnessSmooth.y) / 240.0;

        // ---- refraction: pull the background through the wavy surface ----
        #ifdef WATER_REFRACTION
        if (isWater && isEyeInWater == 0) {
            float depth1c = texture2D(depthtex1, texcoord).r;
            if (depth1c > depth0) {
                vec2 refOff = normalV.xy * 0.045 / max(1.0, -viewPos.z * 0.35);
                vec2 refUv = texcoord + refOff;
                if (texture2D(depthtex1, refUv).r > depth0) {
                    color = texture2D(colortex0, refUv).rgb;
                }
            }
        }
        #endif

        // ---- reflections ----
        #if WATER_REFLECTIONS == 2
        {
            float fresnel = 0.02 + 0.98 * pow(1.0 - max(dot(-viewDir, normalV), 0.0), 5.0);
            float strength = fresnel * 0.9;
            if (!isWater && !isGlass) strength = puddle * 2.2 * fresnel;
            if (strength > 0.005) {
                vec3 reflDir = reflect(viewDir, normalV);
                vec4 ssr = traceSSR(viewPos, reflDir, dither);

                vec3 sunW = normalize(mat3(gbufferModelViewInverse) * sunPosition);
                vec3 reflDirW = normalize(mat3(gbufferModelViewInverse) * reflDir);
                reflDirW.y = abs(reflDirW.y) * 0.9 + 0.1;
                vec3 skyFallback = skyGradient(reflDirW, sunW, rainStrength)
                                 * (0.2 + 0.8 * eyeSky);
                if (isGlass) skyFallback *= 0.5;             // indoor panes: no fake sky

                vec3 refl = mix(skyFallback, ssr.rgb, ssr.a);

                // emissive boost: torches, lanterns and lava stay visible in
                // reflections even at head-on angles, like real light sources
                float glow = smoothstep(1.2, 3.5, luma(ssr.rgb)) * ssr.a;
                strength = min(strength + glow * (isGlass ? 0.35 : 0.25), 1.0);

                color = mix(color, refl, clamp(strength, 0.0, 1.0));
            }
        }
        #endif
    }

    gl_FragData[0] = vec4(color, 1.0);
}
