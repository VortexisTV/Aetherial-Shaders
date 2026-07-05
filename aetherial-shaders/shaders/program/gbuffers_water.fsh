// Water & translucents fragment stage (wrapper adds #version + DRAWBUFFERS:03).
#include "/lib/lighting.glsl"
#include "/lib/water.glsl"

uniform sampler2D texture;
uniform mat4 gbufferModelView;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform int isEyeInWater;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormalW;
varying vec3 vRelPos;
varying float vIsWater;
varying float vIsGlass;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * vColor;
    float dither = bayer8(gl_FragCoord.xy);
    vec3 absPos = vRelPos + cameraPosition;

    vec3 normalW = vNormalW;
    float mask = 0.0;
    vec4 outColor;

    if (vIsWater > 0.5) {
        // animated detail normal on near-horizontal surfaces
        #ifdef WATER_WAVES
        vec3 detail = waterNormal(absPos.xz, frameTimeCounter, WATER_WAVE_HEIGHT);
        normalW = normalize(mix(vNormalW, detail, clamp(vNormalW.y, 0.0, 1.0) * 0.85));
        #endif

        // deep fantasy water body color, biome tint preserved
        vec3 waterTint = mix(vec3(0.06, 0.24, 0.38), vColor.rgb * 0.55, 0.45);

        float sunVis;
        vec3 lit = doLighting(waterTint, vRelPos, normalW, lmcoord, 0.0, 0.0, dither, sunVis);

        vec3 V = -normalize(vRelPos);
        float fresnel = 0.02 + 0.98 * pow(1.0 - max(dot(V, normalW), 0.0), 5.0);
        fresnel *= smoothstep(0.3, 0.9, lmcoord.y);          // no sky mirror in caves

        // sky reflection baked in when SSR is off; faint base when SSR overlays
        #if WATER_REFLECTIONS >= 1
        vec3 reflDirW = reflect(-V, normalW);
        reflDirW.y = abs(reflDirW.y) * 0.9 + 0.1;
        vec3 skyRefl = skyGradient(reflDirW, sunDirWorld(), rainStrength);
            #if WATER_REFLECTIONS == 1
            lit = mix(lit, skyRefl, fresnel * 0.9);
            #else
            lit = mix(lit, skyRefl, fresnel * 0.30);
            #endif
        #endif

        // sun glitter
        vec3 sunCol = aetherialSunColor(sunDirWorld().y) * (1.0 - rainStrength * 0.85);
        lit += sunCol * specHighlight(normalW, V, lightDirWorld(), 0.08) * sunVis * 1.5;

        float alpha = clamp(mix(0.58, 0.95, fresnel), 0.0, 1.0);
        if (isEyeInWater == 1) alpha = 0.35;                 // looking up from below
        outColor = vec4(lit, alpha);
        mask = 1.0;
    } else if (vIsGlass > 0.5) {
        // glass: keep even fully-transparent pane centers alive so the
        // SSR pass can paint reflections across the whole surface
        vec3 base = albedo.a > 0.05 ? albedo.rgb : vColor.rgb * 0.85;
        float sunVis;
        vec3 lit = doLighting(base, vRelPos, vNormalW, lmcoord, 0.0, 0.0, dither, sunVis);

        vec3 V = -normalize(vRelPos);
        float fresnel = 0.03 + 0.97 * pow(1.0 - max(dot(V, vNormalW), 0.0), 5.0);

        // glint of the key light on the pane
        vec3 sunCol = aetherialSunColor(sunDirWorld().y) * (1.0 - rainStrength * 0.85);
        lit += sunCol * specHighlight(vNormalW, V, lightDirWorld(), 0.05) * sunVis;

        float alpha = clamp(max(albedo.a * 0.95, fresnel * 0.7), 0.02, 1.0);
        outColor = vec4(lit, alpha);
        mask = 0.6;                                          // SSR: glass band
    } else {
        if (albedo.a < 0.05) discard;
        float sunVis;
        vec3 lit = doLighting(albedo.rgb, vRelPos, vNormalW, lmcoord, 0.0, 0.0, dither, sunVis);
        outColor = vec4(lit, albedo.a);
        mask = 0.0;                                          // other translucents: no SSR
    }

    vec3 normalV = normalize(mat3(gbufferModelView) * normalW);
    gl_FragData[0] = outColor;
    gl_FragData[1] = encodeGData(normalV, mask);
}
