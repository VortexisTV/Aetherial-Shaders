// Water & translucents vertex stage (shared; wrapper adds #version).
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
varying vec3 vRelPos;
varying float vIsWater;
varying float vIsGlass;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 relPos = gbufferModelViewInverse * viewPos;
    vec3 absPos = relPos.xyz + cameraPosition;

    float id = mc_Entity.x;
    vIsWater = (id > 10007.5 && id < 10008.5) ? 1.0 : 0.0;
    vIsGlass = (id > 10008.5 && id < 10009.5) ? 1.0 : 0.0;

    // gentle vertex swell on the water surface
    if (vIsWater > 0.5) {
        relPos.y += waterWaveHeight(absPos.xz, frameTimeCounter);
    } else {
        float topVertex = (gl_MultiTexCoord0.t < mc_midTexCoord.t) ? 1.0 : 0.0;
        relPos.xyz += vegetationWave(id, absPos, topVertex, frameTimeCounter, rainStrength);
    }

    gl_Position = gl_ProjectionMatrix * (gbufferModelView * relPos);

    texcoord = gl_MultiTexCoord0.xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;
    vNormalW = normalize(mat3(gbufferModelViewInverse) * (gl_NormalMatrix * gl_Normal));
    vRelPos = relPos.xyz;
}
