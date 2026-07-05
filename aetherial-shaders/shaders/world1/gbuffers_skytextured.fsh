#version 120
/* DRAWBUFFERS:0 */
// Vanilla End sky texture, dimmed and pushed violet.
uniform sampler2D texture;

varying vec2 texcoord;
varying vec4 vColor;

void main() {
    vec4 tex = texture2D(texture, texcoord) * vColor;
    gl_FragData[0] = vec4(tex.rgb * vec3(0.75, 0.55, 1.05) * 0.55, tex.a);
}
