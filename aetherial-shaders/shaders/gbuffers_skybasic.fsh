#version 120
/* DRAWBUFFERS:0 */
// Procedural sky: day/night gradients, sunrise & sunset bands, stars.
#include "/lib/sky.glsl"

uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform float rainStrength;
uniform float frameTimeCounter;

varying vec3 vViewDir;

void main() {
    vec3 dirW = normalize(mat3(gbufferModelViewInverse) * vViewDir);
    vec3 sunW = normalize(mat3(gbufferModelViewInverse) * sunPosition);

    vec3 sky = skyGradient(dirW, sunW, rainStrength);

    // stars fade in as the sun sets, hidden by rain
    float night = smoothstep(0.05, -0.12, sunW.y);
    sky += vec3(0.9, 0.95, 1.1) * starField(dirW, frameTimeCounter)
         * night * (1.0 - rainStrength) * 0.6;

    gl_FragData[0] = vec4(sky, 1.0);
}
