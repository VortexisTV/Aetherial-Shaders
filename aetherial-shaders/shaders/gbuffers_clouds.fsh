#version 120
/* DRAWBUFFERS:0 */
#include "/lib/sky.glsl"

uniform sampler2D texture;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float rainStrength;

varying vec2 texcoord;
varying vec4 vColor;

void main() {
    #ifdef VOLUMETRIC_CLOUDS
    discard;
    #else
    vec4 tex = texture2D(texture, texcoord) * vColor;
    vec3 sunW = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 amb = skyAmbientColor(sunW.y, rainStrength);
    vec3 sun = aetherialSunColor(sunW.y);
    gl_FragData[0] = vec4(tex.rgb * (amb * 1.1 + sun * 0.25), tex.a * 0.8);
    #endif
}
