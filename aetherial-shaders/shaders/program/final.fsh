// Final pass (wrapper supplies #version + dimension define).
#include "/lib/common.glsl"
#include "/lib/tonemap.glsl"
#include "/lib/noise.glsl"

uniform sampler2D colortex0;
uniform sampler2D colortex2;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float near;
uniform float far;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float centerDepthSmooth;
uniform int isEyeInWater;
uniform ivec2 eyeBrightnessSmooth;

varying vec2 texcoord;

void main() {
    vec2 uv = texcoord;
    float t = frameTimeCounter;

    // ---- refractive screen distortion -------------------------------
    #ifdef NETHER_DIM
    // heat haze
    uv += vec2(sin(uv.y * 40.0 + t * 2.6), cos(uv.x * 36.0 + t * 2.1))
        * 0.0012 * NETHER_HAZE_STRENGTH;
    #endif
    if (isEyeInWater == 1) {
        uv += vec2(sin(uv.y * 22.0 + t * 1.6), sin(uv.x * 19.0 + t * 1.3)) * 0.0035;
    } else if (isEyeInWater == 2) {
        uv += vec2(sin(uv.y * 14.0 + t * 3.2), cos(uv.x * 12.0 + t * 2.8)) * 0.006;
    }
    uv = clamp(uv, vec2(0.001), vec2(0.999));

    vec3 color = texture2D(colortex0, uv).rgb;
    float depth = texture2D(depthtex0, uv).r;
    bool isHand = depth < 0.56;

    // ---- depth of field ----------------------------------------------
    #ifdef DOF
    if (!isHand) {
        // lens-equation CoC: blur ~ |1/focus - 1/dist| (in blocks).
        // Focusing far keeps the background sharp (hyperfocal) while
        // close foreground melts, like a real camera.
        float dist  = linearDepth(depth, near, far) * far;
        float focus = linearDepth(centerDepthSmooth, near, far) * far;
        float coc = abs(1.0 / max(focus, 1.0) - 1.0 / max(dist, 1.0));
        coc = clamp(coc * 10.0 * DOF_STRENGTH, 0.0, 1.0);
        coc = smoothstep(0.05, 1.0, coc);
        float radius = coc * 0.010;
        if (radius > 0.0006) {
            vec3 acc = color;
            float n = 1.0;
            for (int i = 0; i < 12; i++) {
                float ang = float(i) * 2.39996;
                float r = sqrt((float(i) + 0.5) / 12.0) * radius;
                vec2 o = vec2(cos(ang) / aspectRatio, sin(ang)) * r;
                acc += texture2D(colortex0, clamp(uv + o, 0.0, 1.0)).rgb;
                n += 1.0;
            }
            color = acc / n;
        }
    }
    #endif

    // ---- camera motion blur -------------------------------------------
    #ifdef MOTION_BLUR
    if (!isHand) {
        vec3 viewPos = screenToView(vec3(uv, depth), gbufferProjectionInverse);
        vec3 relPos = (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;
        vec3 prevRel = relPos + cameraPosition - previousCameraPosition;
        vec4 prevClip = gbufferPreviousProjection * (gbufferPreviousModelView * vec4(prevRel, 1.0));
        if (prevClip.w > 0.0) {
            vec2 prevUv = prevClip.xy / prevClip.w * 0.5 + 0.5;
            vec2 vel = (uv - prevUv) * 0.35 * MB_STRENGTH;
            float speed = length(vel * vec2(viewWidth, viewHeight));
            if (speed > 0.5) {
                vec3 acc = color;
                float n = 1.0;
                for (int i = 1; i <= 5; i++) {
                    vec2 p = uv - vel * (float(i) / 5.0);
                    if (clamp(p, 0.0, 1.0) != p) break;
                    acc += texture2D(colortex0, p).rgb;
                    n += 1.0;
                }
                color = acc / n;
            }
        }
    }
    #endif

    // ---- bloom -----------------------------------------------------------
    #ifdef BLOOM
    vec3 bloom = texture2D(colortex2, uv).rgb;
    color += bloom * BLOOM_INTENSITY * 0.40;
    #endif

    // ---- exposure ---------------------------------------------------------
    float exposure = exp2(EXPOSURE);
    #ifdef AUTO_EXPOSURE
    float eyeSky = float(eyeBrightnessSmooth.y) / 240.0;
    float eyeBlock = float(eyeBrightnessSmooth.x) / 240.0;
    float adapt = max(eyeSky, eyeBlock * 0.7);
    exposure *= mix(1.55, 0.85, adapt);          // brighten caves, tame noon
    #endif
    color *= exposure;

    // ---- lens flare (before tonemap so it can bloom out) -------------------
    #if defined LENS_FLARE && defined OVERWORLD_DIM
    {
        vec4 sunClip = gbufferProjection * vec4(sunPosition, 1.0);
        if (sunClip.w > 0.0) {
            vec2 sunUv = sunClip.xy / sunClip.w * 0.5 + 0.5;
            if (clamp(sunUv, -0.2, 1.2) == sunUv && texture2D(depthtex0, clamp(sunUv, 0.001, 0.999)).r >= 1.0) {
                vec2 rel = (uv - sunUv) * vec2(aspectRatio, 1.0);
                vec2 mid = (uv - 0.5) * vec2(aspectRatio, 1.0);
                float sunAmt = exp(-length(rel) * 9.0);
                // ghost sprites mirrored through screen center
                float ghosts = 0.0;
                vec2 axis = (vec2(0.5) - sunUv) * vec2(aspectRatio, 1.0);
                for (int i = 1; i <= 3; i++) {
                    vec2 gpos = axis * (float(i) * 0.55);
                    ghosts += exp(-length(rel - gpos) * (14.0 + float(i) * 8.0)) * (0.5 / float(i));
                }
                // anamorphic streak
                float streak = exp(-abs(rel.y) * 60.0) * exp(-abs(rel.x) * 3.5) * 0.6;
                float vis = (1.0 - rainStrength) * LENS_FLARE_STRENGTH;
                color += (vec3(1.0, 0.85, 0.6) * sunAmt * 0.35
                        + vec3(0.6, 0.8, 1.0) * ghosts * 0.25
                        + vec3(0.9, 0.75, 1.0) * streak * 0.20) * vis;
            }
        }
    }
    #endif

    // ---- tonemap + grade -----------------------------------------------------
    color = acesFilm(color);
    color = colorGrade(color);

    // ---- vignette ---------------------------------------------------------
    #ifdef VIGNETTE
    vec2 v = (texcoord - 0.5) * vec2(aspectRatio, 1.0);
    color *= 1.0 - dot(v, v) * 0.20;
    #endif

    // kill gradient banding
    color += (bayer8(gl_FragCoord.xy) - 0.5) / 255.0;

    gl_FragColor = vec4(color, 1.0);
}
