#version 120
// Shadow map pass: distorted ortho projection, waving vegetation matched
// to the visible geometry so shadows follow the wind.
#include "/lib/wave.glsl"
#include "/lib/distort.glsl"

attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform vec3 cameraPosition;
uniform float frameTimeCounter;
uniform float rainStrength;

varying vec2 texcoord;
varying vec4 vColor;

void main() {
    vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
    vec4 relPos  = shadowModelViewInverse * viewPos;
    vec3 absPos  = relPos.xyz + cameraPosition;

    float topVertex = (gl_MultiTexCoord0.t < mc_midTexCoord.t) ? 1.0 : 0.0;
    relPos.xyz += vegetationWave(mc_Entity.x, absPos, topVertex, frameTimeCounter, rainStrength);

    vec4 clip = gl_ProjectionMatrix * (shadowModelView * relPos);
    clip.xyz = distortShadowClip(clip.xyz);
    gl_Position = clip;

    texcoord = gl_MultiTexCoord0.xy;
    vColor = gl_Color;
}
