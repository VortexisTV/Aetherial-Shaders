// Terrain fragment stage (shared; wrapper supplies #version + DRAWBUFFERS:03).
#include "/lib/lighting.glsl"
#include "/lib/noise.glsl"

uniform sampler2D texture;
uniform vec3 cameraPosition;
uniform float wetness;
uniform float frameTimeCounter;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormalW;
varying vec3 vNormalV;
varying vec3 vRelPos;
varying float vSubsurface;
varying float vEmissive;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * vColor;
    if (albedo.a < 0.102) discard;

    float dither = bayer8(gl_FragCoord.xy);
    vec3 absPos = vRelPos + cameraPosition;

    // ---- rain-wet ground & puddles --------------------------------
    float puddle = 0.0;
    #ifdef RAIN_PUDDLES
    if (wetness > 0.01 && vNormalW.y > 0.85 && lmcoord.y > 0.87) {
        float n = fbm(absPos.xz * 0.10, 3, vec2(0.0));
        puddle = smoothstep(1.0 - PUDDLE_AMOUNT * 0.55, 1.0 - PUDDLE_AMOUNT * 0.55 + 0.18, n);
        puddle *= wetness;
        // wet surfaces darken and saturate slightly
        albedo.rgb *= 1.0 - 0.25 * wetness * smoothstep(0.8, 1.0, lmcoord.y);
        albedo.rgb = mix(albedo.rgb, albedo.rgb * albedo.rgb * 1.35, puddle * 0.5);
    }
    #endif

    float sunVis;
    vec3 col = doLighting(albedo.rgb, vRelPos, vNormalW, lmcoord,
                          vSubsurface, vEmissive, dither, sunVis);

    // specular streak on wet ground
    #ifdef RAIN_PUDDLES
    if (puddle > 0.001) {
        vec3 V = -normalize(vRelPos);
        vec3 L = lightDirWorld();
        vec3 sunCol = aetherialSunColor(sunDirWorld().y) * (1.0 - rainStrength * 0.7);
        col += sunCol * specHighlight(vec3(0.0, 1.0, 0.0), V, L, 0.15) * sunVis * puddle;
    }
    #endif

    gl_FragData[0] = vec4(col, albedo.a);
    gl_FragData[1] = encodeGData(vNormalV, 0.35 * puddle);
}
