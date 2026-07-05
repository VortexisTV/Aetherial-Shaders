# Aetherial Shaders

A cinematic **modern fantasy realism** shaderpack for Minecraft Java Edition.
Compatible with **Iris** (1.16+ recommended pipeline) and **OptiFine** (HD U G8 or newer).
Written against the classic GLSL 120 shader dialect for maximum driver compatibility.

Minecraft, but with a high-end fantasy film treatment: soft golden-hour sunlight,
dynamic shadows, volumetric fog and god rays, living water, glowing emissives and a
filmic ACES grade — while keeping the blocky identity, readable nights and honest
performance.

## Installing

1. Install **Iris** (recommended, via the Iris/Fabric installer) or **OptiFine**.
2. Drop `Aetherial-Shaders-v1.0.zip` into your `.minecraft/shaderpacks/` folder
   (or copy the `aetherial-shaders` folder itself — the loader accepts both).
3. In-game: **Options → Video Settings → Shader Packs → Aetherial**.
4. Pick a profile in **Shader Pack Settings** (gear icon): Low / Medium / High / Ultra.

## Feature map

| Feature | Where it lives |
|---|---|
| Golden-hour sunlight & day cycle colors | `lib/sky.glsl` (`aetherialSunColor`) |
| Dynamic PCF shadows (terrain, mobs, buildings) | `shadow.*`, `lib/shadows.glsl` |
| Volumetric god rays (shadow-map march) | `program/composite.fsh` |
| Volumetric cloud deck, stars, sunset gradients | `lib/sky.glsl`, `gbuffers_skybasic.fsh` |
| Water waves, refraction, SSR reflections, caustics | `program/gbuffers_water.*`, `composite1.fsh` |
| Rain-wet ground & puddle reflections | `program/gbuffers_terrain.fsh` |
| Emissive lava / torches / redstone / soul fire | `block.properties` + `lib/lighting.glsl` |
| SSAO for corners and caves | `program/composite.fsh` |
| Underwater blue fog, distortion, light shafts | `composite`/`final` (`isEyeInWater`) |
| Nether red fog + heat haze | `world-1/` overrides |
| End purple void atmosphere | `world1/` overrides |
| Bloom, auto exposure, ACES tonemap, grading, lens flare, vignette | `composite2/3.fsh`, `program/final.fsh` |
| Motion blur & depth of field (Ultra) | `program/final.fsh` |

## Profiles

- **Low** — 1024 shadow map, fast filtering, no SSAO/god rays/volumetric clouds,
  sky-only water reflections. Targets mid-range PCs at high framerates.
- **Medium** — 2048 shadows, god rays, volumetric clouds, ray-traced water.
- **High** — the intended look: 3072 shadows, soft PCF, full atmosphere.
- **Ultra** — 4096 shadows, 32-sample volumetrics, 32-step reflections, plus
  cinematic depth of field and motion blur.

Every individual effect can still be toggled per-option in the menu
(bloom, DoF, motion blur, reflections, clouds, fog density, grading, exposure,
waving foliage, puddles, lens flare, and more).

## Tuning cheat-sheet

- Too dark at night / in caves → raise **Minimum Light** or **Night Brightness**.
- Shadow acne or peter-panning → bias lives in `lib/shadows.glsl` (`bias` and the
  normal-offset factor).
- Fog too thick → **Fog Density** slider; per-dimension multipliers are in
  `program/composite.fsh`.
- Bloom taste → threshold in `composite2.fsh` (`smoothstep(1.6, 3.2, l)`),
  intensity in the menu.
- Water color → `waterTint` in `program/gbuffers_water.fsh`.
- Golden-hour intensity → `golden` color in `lib/sky.glsl`.

## Structure notes

- Root programs render the overworld; `world-1/` (Nether) and `world1/` (End)
  contain thin wrappers that re-include the shared program bodies from
  `program/` with a dimension define (`NETHER_DIM` / `END_DIM`).
- Buffers: `colortex0` HDR scene, `colortex2` bloom, `colortex3` encoded
  view-normal + reflectance mask (water = 1.0, puddles ≈ 0.35).
- Shadows sample `shadowtex1` (opaque casters only) so light passes through
  water and glass, keeping underwater shafts bright.
