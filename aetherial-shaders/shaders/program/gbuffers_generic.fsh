// Shared fragment stage for entities, block entities, hand and particles.
// Wrapper may define: GEN_ENTITY (hurt flash), GEN_PARTICLE (softer shading).
#include "/lib/lighting.glsl"

uniform sampler2D texture;

#ifdef GEN_ENTITY
uniform vec4 entityColor;
#endif

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormalW;
varying vec3 vNormalV;
varying vec3 vRelPos;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * vColor;
    if (albedo.a < 0.05) discard;

    #ifdef GEN_ENTITY
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);
    #endif

    float dither = bayer8(gl_FragCoord.xy);

    #ifdef GEN_PARTICLE
    // particles: treat as double-sided fluff, no hard directionality
    float sunVis;
    vec3 col = doLighting(albedo.rgb, vRelPos, vec3(0.0, 1.0, 0.0), lmcoord,
                          1.0, 0.0, dither, sunVis);
    #else
    float sunVis;
    vec3 col = doLighting(albedo.rgb, vRelPos, vNormalW, lmcoord,
                          0.0, 0.0, dither, sunVis);
    #endif

    gl_FragData[0] = vec4(col, albedo.a);
    gl_FragData[1] = encodeGData(vNormalV, 0.0);
}
