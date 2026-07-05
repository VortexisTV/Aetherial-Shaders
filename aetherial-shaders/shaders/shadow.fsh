#version 120

uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 vColor;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * vColor;
    if (albedo.a < 0.1) discard;
    gl_FragData[0] = albedo;
}
