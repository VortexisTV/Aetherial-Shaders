// ============================================================
//  AETHERIAL SHADERS - settings.glsl
//  Every user-facing option lives here. OptiFine/Iris parse the
//  trailing // [..] comments to build the in-game menu.
// ============================================================
#ifndef SETTINGS_GLSL
#define SETTINGS_GLSL

// ---------------- Lighting & shadows ----------------
#define SHADOWS                       // Dynamic sun/moon shadows from terrain, mobs and buildings
#define SHADOW_PCF 2                  // [0 1 2 3] Shadow filtering: hard -> cinematic soft
#define SHADOW_SOFTNESS 1.0           // [0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0]
#define SSAO                          // Screen-space ambient occlusion in corners and caves
#define SSAO_QUALITY 2                // [1 2 3]
#define MIN_LIGHT 0.4                 // [0.0 0.2 0.4 0.6 0.8 1.0] Ambient floor so caves stay readable
#define NIGHT_BRIGHTNESS 1.0          // [0.5 0.75 1.0 1.25 1.5 2.0]
#define EMISSIVE_STRENGTH 1.0         // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0] Lava / torch / lantern glow
#define HANDLIGHT                     // Held torches light the world around you

// ---------------- Atmosphere ----------------
#define GODRAYS                       // Volumetric light shafts marched through the shadow map
#define VL_SAMPLES 16                 // [8 12 16 24 32]
#define VL_STRENGTH 1.0               // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define FOG_DENSITY 1.0               // [0.0 0.25 0.5 0.75 1.0 1.25 1.5 2.0 2.5 3.0]
#define VOLUMETRIC_CLOUDS             // Layered noise clouds lit by the sun (replaces vanilla clouds)
#define CLOUD_OCTAVES 5               // [3 4 5 6]
#define CLOUD_COVERAGE 1.0            // [0.5 0.75 1.0 1.25 1.5]
#define NETHER_HAZE_STRENGTH 1.0      // [0.0 0.5 1.0 1.5 2.0]

// ---------------- Water ----------------
#define WATER_REFLECTIONS 2           // [0 1 2] Off / Sky only / Screen-space ray traced
#define SSR_STEPS 24                  // [12 16 24 32]
#define WATER_REFRACTION              // Refraction distortion of the world seen through water
#define WATER_CAUSTICS                // Animated light caustics under water
#define WATER_WAVES                   // Vertex + normal waves on the water surface
#define WATER_WAVE_HEIGHT 1.0         // [0.25 0.5 0.75 1.0 1.25 1.5 2.0]

// ---------------- Surfaces ----------------
#define WAVING_LEAVES                 // Leaves sway in the wind
#define WAVING_PLANTS                 // Grass, flowers and crops sway
#define RAIN_PUDDLES                  // Wet, reflective ground while it rains
#define PUDDLE_AMOUNT 0.6             // [0.2 0.4 0.6 0.8 1.0]

// ---------------- Camera ----------------
#define BLOOM                         // Soft glow around bright light sources
#define BLOOM_INTENSITY 1.0           // [0.25 0.5 0.75 1.0 1.25 1.5 2.0]
#define AUTO_EXPOSURE                 // Eye adaptation between caves and daylight
#define EXPOSURE 0.0                  // [-1.0 -0.75 -0.5 -0.25 0.0 0.25 0.5 0.75 1.0]
//#define MOTION_BLUR                 // Camera motion blur
#define MB_STRENGTH 0.5               // [0.25 0.5 0.75 1.0]
//#define DOF                         // Cinematic depth of field focused at the crosshair
#define DOF_STRENGTH 1.0              // [0.5 0.75 1.0 1.5 2.0]
#define LENS_FLARE                    // Anamorphic-style flare when facing the sun
#define LENS_FLARE_STRENGTH 1.0       // [0.25 0.5 0.75 1.0 1.5]
#define VIGNETTE                      // Gentle darkening of screen edges

// ---------------- Color ----------------
#define COLOR_GRADING                 // Filmic grade: temperature, vibrance, contrast
#define SATURATION 1.0                // [0.7 0.8 0.9 1.0 1.1 1.2 1.3]
#define VIBRANCE 1.15                 // [0.8 0.9 1.0 1.1 1.15 1.2 1.3 1.5]
#define CONTRAST 1.02                 // [0.9 0.95 1.0 1.02 1.05 1.1 1.15]
#define TEMPERATURE 0.0               // [-1.0 -0.75 -0.5 -0.25 0.0 0.25 0.5 0.75 1.0]

// ---------------- Pipeline constants (also user tunable) ----------------
const int   shadowMapResolution      = 2048;   // [1024 2048 3072 4096]
const float shadowDistance           = 160.0;  // [96.0 112.0 128.0 160.0 192.0 256.0]
const float sunPathRotation          = -35.0;  // [-50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0]
const float shadowDistanceRenderMul  = 1.0;
const float ambientOcclusionLevel    = 1.0;
const float centerDepthHalflife      = 0.5;   // how fast the camera refocuses
const float eyeBrightnessHalflife    = 8.0;
const float wetnessHalflife          = 300.0;
const float drynessHalflife          = 100.0;

/*
Buffer formats are directives read by the shader loader, not GLSL code,
so they must stay inside this comment block:
const int colortex0Format = RGBA16F;   // HDR scene color
const int colortex2Format = RGBA16F;   // bloom scratch
const int colortex3Format = RGBA16;    // encoded normal + reflectance mask
*/
const bool colortex2Clear = true;
const bool colortex3Clear = true;
const vec4 colortex3ClearColor = vec4(0.5, 0.5, 0.0, 0.0);

#endif // SETTINGS_GLSL
