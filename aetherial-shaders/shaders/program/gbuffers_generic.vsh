// Shared vertex stage for entities, block entities, hand and particles.
#include "/lib/common.glsl"

uniform mat4 gbufferModelViewInverse;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;
varying vec3 vNormalW;
varying vec3 vNormalV;
varying vec3 vRelPos;

void main() {
    gl_Position = ftransform();

    texcoord = gl_MultiTexCoord0.xy;
    lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
    vColor = gl_Color;

    vNormalV = normalize(gl_NormalMatrix * gl_Normal);
    vNormalW = normalize(mat3(gbufferModelViewInverse) * vNormalV);
    vRelPos = (gbufferModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz;
}
