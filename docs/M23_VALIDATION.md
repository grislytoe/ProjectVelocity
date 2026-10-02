# M23 Art Pass — validation evidence

Date: 2026-10-01. Workspace: `C:/Godot Projects/ProjectVelocity`; branch
`feature/m23-art-pass`; base `origin/dev`
`917a5f60ccb47640e89c96dc6943bcd71ac7164d`. Godot
4.7.2.stable.official.ed1daf0bf, Windows OpenGL Compatibility on AMD Radeon Graphics.
Runtime **0.23.0-dev / build29**; protocol **5 / wire4**; save schema **5**.

The unrelated user `project.godot` remains byte-identical SHA-256
`5B9713ACA5045DD697EA09DF21E9DE658283B782B3B0C8F2CC540539FABB65AC`
and is excluded from the M23 commit.

## Delivered visual pass

- Refined the rigid modular android while preserving all 14 required states, detached
  `PlayerVisualFrame`/animation boundary, eight-direction Dash, speed-linked Run,
  Skid/Turnaround, readiness, invulnerability and local-only Dash selection.
- Added shared palette and shape grammar for static/one-way/moving/breakable/Jump Pad surfaces,
  spikes/saws/lasers/turrets/projectiles and Start/checkpoint/Finish progression.
- Unified AppUI, settings, lobby, online lifecycle/reconnect/results and HUD with native
  scalable Controls, code-native mark and the existing 200 ms transition/focus contracts.
- Added curated `VisualAssetRegistry` plus tooling-readable JSON manifest. Runtime never loads a
  map/profile-provided path. Training remains theme-neutral.

## Generated asset and provenance

One production-oriented far plate is integrated:

| ID | Runtime path | Source/export | Budget |
| --- | --- | --- | ---: |
| `industrial_foundry_far_v1` | `res://visuals/environment/industrial_foundry_far.webp` | OpenAI built-in ImageGen; 2026-10-01; raw 1792×896 PNG visually reviewed outside git; Lanczos 1024×512, contrast .82, saturation .78, WebP q84 | 22,444 bytes source; 2,097,152 estimated decoded RGBA bytes |

The exact positive/negative prompt and cleanup/rejection workflow are in
`docs/ASSET_GENERATION_PROMPTS.md`. There are no web/third-party assets, raw generations,
rejected variants, 2K/4K textures or new runtime dependencies. Import is linear, lossless
Godot texture import, no mipmaps and no repeat because the plate is displayed enlarged.
`IndustrialFoundryBackground.PLATE` preloads it before control; the node is process-disabled,
non-colliding and behind authored route geometry.

## Automated regression

`./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe` completed with exit 0 and final marker:

```text
M0-M23 validation passed, including art budgets and production 2700-tick reconnect expiry / localhost ENet scenarios.
```

This includes import, every parser, isolated headless boot, M0–M23 tests, M15–M22 two-process
localhost scenarios, M17 matrix, M21 series/UI, M22 reconnect at render30/60/144, Git whitespace
and test-store cleanup. `tests/art_pass_test.gd` reports
`PROJECTVELOCITY_M23_ART_OK (75 checks)`: curated paths, manifest, dimensions/memory/import,
preload/process/z-order, five platform grammars, 14-state inventory, 25 body/accent combinations,
local/remote policy and pool bounds.

Unchanged deterministic traces:

| Trace | SHA-256 |
| --- | --- |
| M3 movement / presentation removed | `a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277` |
| M5 camera | `6640203a07124a35289a00f60d7ab13cb80403f550082bded7a9dea172944fc4` |
| M8 platforms | `0e2e98ba055b78b3f98571fd8f89a3ed75494a959c049de447bcbf57cfb871dd` |
| M9 hazards | `6ccebac3b8552e612ba623e09692c3855e0bcda60d8958a517b3607db01599d1` |
| M10 Solo | `a2fa3ee3f37a1f2ab92cdbc8a136df014654988280d01c68ee11cffc0adcac36` |
| M14 main route | `099130fa102a2d903ba1b79c75b32b46310281f160b0d7dab49d165e86beaa4a` |
| M14 shortcut | `db6d91aacabb30c9d12b596e293e9d96d47699512e7ade6499c701df30576042` |
| M14 recovery | `039eac99781dca063a48fb9e22f4f46d7f39a5e1dc6473b072640ee4230d772c` |

M14 main remains 3933 ticks / 65.550 s, seven checkpoints, zero deaths; shortcut/recovery
fixtures retain their prior outcomes. Collision shapes, movement tuning, platform route/timing,
hazard damage/timing, checkpoint order, network authority and record/save semantics are unchanged.

## Map identity

PV-MAP-1 conservatively includes shared gameplay/visual scripts, so the art pass deliberately
publishes new official identities while retaining all historical PB keys:

| Map | Previous → M23 version | M23 checksum |
| --- | ---: | --- |
| Training Circuit (`solo_training`) | 6 → **7** | `59b0ff23a5b2c6360a35f8a538b0e4b3207ffbaf430bead7d302e3049c881992` |
| Foundry Run (`industrial_foundry`) | 5 → **6** | `8a7ff588ae3f2dc37e8b370d5a4bdd9077601a49ab8716551e7e208a3769b654` |

`check_trial_hash.ps1 -Update` generated these values and the full validator rechecked them.
No map geometry/checkpoint/route/hazard data changed.

## Normal renderer and visual inspection

Ignored before/after evidence is under `builds/validation/m23/`. Captures cover the 14-pose
gallery with local/30% remote pairs, all Foundry sections, six hazard stations, EN/RU menu,
settings/customization/online/pause states and logical world targets at 1280×720 (inside the
1280×800 selection), 1280×800 and 1920×1080. OpenGL Compatibility reported no renderer/parser
errors or warnings.

Visual review checked the 64 px avatar, body/accent separation, weak remote treatment, route
edge priority, generated-background subordination, platform silhouette cues, spike/saw/laser/
turret channels and progression markers. Additional captures exercise High Contrast,
Deuteranopia/Balanced and flash-disabled/Performance; shape cues remain visible. SettingsRuntime
native test confirms window/render transitions, fixed 1920×1080 logical framing and RU/EN focus.

## Performance sanity (not M24)

`dev_tools/art_performance_smoke.gd` instantiated the full Foundry and sampled 180 rendered
frames at fixed 60 FPS after 30 warm-up frames:

- frame time p50 **16.669 ms**, p95 **17.071 ms**, max **17.842 ms**;
- draw calls p95/max **103**; primitives p95 **3030**;
- committed raster decoded estimate **2.0 MiB**; `texture_preloaded=true`;
- course construction on this run **947.085 ms**, paid before control; no lazy first-use asset
  load or repeated VFX allocation was observed;
- physics remains 60 Hz and network/snapshot rates are unchanged.

This is a local sanity sample on one Windows GPU, not a target-hardware benchmark or M24 claim.

## Security, packaging and remaining review

Git whitespace passes. Save/secret scan found no save files, credentials, key material or raw
generation outputs; matches are only documented EOS environment-variable names. Local official
Godot 4.7.2 export templates are absent, so Windows export/boot is owned by PR CI; do not claim a
local export. Physical Steam Deck/Linux/controller, target-low-end profiling and subjective
final-art acceptance remain manual.

M19 live EOS/Internet remains **BLOCKED**: production Auth/Connect/Lobby/P2P, authorized
identities, native exports and real Internet evidence are still absent. M15–M22 local ENet and
M23 visual evidence do not satisfy that gate.
