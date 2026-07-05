// Celestial colors, procedural sky gradient, stars and the volumetric
// cloud layer. All directions are WORLD space, sunH = sunDirW.y.
#ifndef SKY_GLSL
#define SKY_GLSL

#include "/lib/common.glsl"
#include "/lib/noise.glsl"

// ---------- key light (sun by day, moon by night), HDR ----------
vec3 aetherialSunColor(float sunH) {
    vec3 noon   = vec3(1.00, 0.96, 0.90) * 3.2;
    vec3 golden = vec3(1.25, 0.58, 0.26) * 2.6;
    vec3 moon   = vec3(0.30, 0.42, 0.68) * 0.45;

    float day    = smoothstep(-0.05, 0.15, sunH);
    float goldenW = 1.0 - smoothstep(0.10, 0.35, abs(sunH));
    vec3 dayCol  = mix(noon, golden, goldenW * 0.85);
    return mix(moon, dayCol, day);
}

// ---------- hemispheric ambient from the sky ----------
vec3 skyAmbientColor(float sunH, float rain) {
    vec3 day    = vec3(0.52, 0.66, 0.95) * 0.85;
    vec3 dusk   = vec3(0.55, 0.42, 0.55) * 0.55;
    vec3 night  = vec3(0.12, 0.17, 0.30) * 0.42 * NIGHT_BRIGHTNESS;

    float dayW  = smoothstep(-0.05, 0.20, sunH);
    float duskW = 1.0 - smoothstep(0.08, 0.30, abs(sunH));
    vec3 col = mix(night, day, dayW);
    col = mix(col, dusk, duskW * 0.6);
    return mix(col, vec3(luma(col)) * vec3(0.9, 0.95, 1.05), rain * 0.8);
}

// ---------- procedural stars ----------
float starField(vec3 dirW, float t) {
    if (dirW.y <= 0.02) return 0.0;
    vec3 p = dirW / max(dirW.y, 0.2);          // project onto a dome slice
    vec2 uv = p.xz * 96.0;
    vec2 cell = floor(uv);
    float star = hash12(cell);
    star = step(0.985, star);                    // sparse
    vec2 center = fract(uv) - 0.5;
    float shape = 1.0 - smoothstep(0.0, 0.35, length(center));
    float twinkle = 0.7 + 0.3 * sin(t * 2.0 + hash12(cell + 7.7) * TAU);
    return star * shape * twinkle * smoothstep(0.02, 0.2, dirW.y);
}

// ---------- full sky gradient ----------
vec3 skyGradient(vec3 dirW, vec3 sunDirW, float rain) {
    float sunH = sunDirW.y;
    float y = max(dirW.y, 0.0);
    float horizon = 1.0 - y;

    float dayW  = smoothstep(-0.10, 0.20, sunH);
    float duskW = 1.0 - smoothstep(0.10, 0.32, abs(sunH));

    // zenith / horizon per time of day
    vec3 zenithDay   = vec3(0.13, 0.32, 0.72);
    vec3 horizonDay  = vec3(0.55, 0.72, 0.98);
    vec3 zenithNight = vec3(0.010, 0.018, 0.048) * NIGHT_BRIGHTNESS;
    vec3 horizonNight= vec3(0.035, 0.055, 0.110) * NIGHT_BRIGHTNESS;

    vec3 zenith  = mix(zenithNight,  zenithDay,  dayW);
    vec3 horizonC= mix(horizonNight, horizonDay, dayW);

    vec3 sky = mix(zenith, horizonC, pow(horizon, 2.5));

    // sunset / sunrise band, strongest toward the sun azimuth
    float sunAmount = max(dot(normalize(dirW.xz + vec2(1e-4)), normalize(sunDirW.xz + vec2(1e-4))), 0.0);
    vec3 duskCol = mix(vec3(0.95, 0.38, 0.18), vec3(0.60, 0.22, 0.42), clamp(-sunH * 6.0 + 0.5, 0.0, 1.0));
    float band = duskW * pow(horizon, 3.0) * (0.35 + 0.65 * sunAmount);
    sky = mix(sky, duskCol, clamp(band * 1.4, 0.0, 1.0));

    // glow around the sun / moon disc
    float d = max(dot(dirW, sunDirW), 0.0);
    sky += aetherialSunColor(sunH) * 0.05 * pow(d, 32.0) * (1.0 - rain * 0.8);
    sky += aetherialSunColor(sunH) * 0.20 * pow(d, 350.0) * (1.0 - rain);

    // rain grays everything down
    vec3 rainSky = vec3(luma(sky)) * vec3(0.85, 0.92, 1.05) * 0.55;
    sky = mix(sky, rainSky, rain * 0.85);

    // darken the void below the horizon
    sky *= mix(0.22, 1.0, smoothstep(-0.38, -0.02, dirW.y));

    return sky;
}

// Where distance fog converges: sky color near the horizon
vec3 fogColorFor(vec3 dirW, vec3 sunDirW, float rain) {
    vec3 flatDir = normalize(vec3(dirW.x, 0.06, dirW.z));
    return skyGradient(flatDir, sunDirW, rain);
}

// ---------- volumetric-style cloud layer ----------
// Ray/plane march against a noise deck at cloudY. Returns rgb + alpha.
#ifdef VOLUMETRIC_CLOUDS
vec4 cloudLayer(vec3 camPosW, vec3 dirW, vec3 sunDirW, float rain, float t, float dither, float maxDist) {
    const float cloudY = 192.0;
    float dy = cloudY - camPosW.y;
    if (dirW.y * sign(dy) <= 0.015) return vec4(0.0);   // looking away from the deck

    float dist = dy / dirW.y;
    if (dist < 0.0 || dist > 6000.0 || dist > maxDist) return vec4(0.0);
    vec2 base = camPosW.xz + dirW.xz * dist;

    vec2 wind = vec2(t * 3.4, t * 1.1);
    float cov = (0.42 + rain * 0.25) * CLOUD_COVERAGE;

    // two stacked density samples fake a lit volume
    float dens = fbm(base * 0.0016 + wind * 0.0016, CLOUD_OCTAVES, vec2(13.1, 7.7));
    dens = smoothstep(1.0 - cov, 1.0 - cov + 0.42, dens);
    if (dens <= 0.003) return vec4(0.0);

    vec2 toSun = base + sunDirW.xz * (140.0 + dither * 60.0);
    float densSun = fbm(toSun * 0.0016 + wind * 0.0016, CLOUD_OCTAVES, vec2(13.1, 7.7));
    densSun = smoothstep(1.0 - cov, 1.0 - cov + 0.42, densSun);
    float lit = clamp(dens - densSun + 0.55, 0.0, 1.0);

    float sunH = sunDirW.y;
    vec3 sunCol = aetherialSunColor(sunH);
    vec3 ambient = skyAmbientColor(sunH, rain);
    vec3 bright = ambient * 1.15 + sunCol * 0.55;
    vec3 dark   = ambient * 0.45 + sunCol * 0.06;
    vec3 col = mix(dark, bright, lit);
    col = mix(col, vec3(luma(col)) * 0.8, rain * 0.6);

    float alpha = clamp(dens * 1.6, 0.0, 1.0);
    alpha *= 1.0 - smoothstep(2500.0, 6000.0, dist);       // fade at distance
    alpha *= smoothstep(0.0, 0.06, abs(dirW.y));
    return vec4(col, alpha * 0.92);
}
#endif

#endif
