// Terrain vertex stage (shared; wrapper supplies #version + world define).
#include "/lib/wave.glsl"

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormalW;
varying vec3 vNormalV;
varying vec3 vRelPos;
varying float vSubsurface;
varying float vEmissive;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 relPos = gbufferModelViewInverse * viewPos;
    vec3 absPos = relPos.xyz + cameraPosition;

    float id = mc_Entity.x;
    float topVertex = (gl_MultiTexCoord0.t < mc_midTexCoord.t) ? 1.0 : 0.0;
    relPos.xyz += vegetationWave(id, absPos, topVertex, frameTimeCounter, rainStrength);

    gl_Position = gl_ProjectionMatrix * (gbufferModelView * relPos);

    texcoord = gl_MultiTexCoord0.xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vNormalV = normalize(gl_NormalMatrix * gl_Normal);
    vNormalW = normalize(mat3(gbufferModelViewInverse) * vNormalV);
    vRelPos = relPos.xyz;

    // foliage gets wrap/backlight; emissive strength per block group
    vSubsurface = (id > 10000.5 && id < 10003.5) ? 1.0 : 0.0;

    float e = 0.0;
    if      (id > 10031.5 && id < 10032.5) e = 3.0;   // lava / fire / magma
    else if (id > 10032.5 && id < 10033.5) e = 2.0;   // torches / lanterns / glowstone
    else if (id > 10033.5 && id < 10034.5) e = 1.3;   // redstone (follows texture redness)
    else if (id > 10034.5 && id < 10035.5) e = 1.9;   // soul fire / sculk (textures are blue)
    else if (id > 10035.5 && id < 10036.5) e = 0.9;   // amethyst / enchanting / portals
    vEmissive = e;
}
