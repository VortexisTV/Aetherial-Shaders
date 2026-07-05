#version 120
/* DRAWBUFFERS:0 */
#include "/lib/sky.glsl"

uniform sampler2D texture;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float rainStrength;

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 vColor;

void main() {
    vec4 tex = texture2D(texture, texcoord) * vColor;
    if (tex.a < 0.01) discard;

    vec3 sunW = normalize(mat3(gbufferModelViewInverse) * sunPosition);
    vec3 amb = skyAmbientColor(sunW.y, rainStrength) + aetherialSunColor(sunW.y) * 0.15;

    // cool the rain streaks slightly, keep them subtle
    vec3 col = tex.rgb * amb * vec3(0.85, 0.95, 1.15) * (0.4 + 0.6 * lmcoord.y);
    gl_FragData[0] = vec4(col, tex.a * 0.75);
}
