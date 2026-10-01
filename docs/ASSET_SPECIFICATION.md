# ProjectVelocity asset specification — M23

This is the production contract for replacing or extending M23 art. `Integrated` means the
asset is active in runtime now; `Future` means a final replacement slot with no arbitrary
runtime loading. All dimensions are pixels unless stated otherwise.

## Global export contract

| Property | Requirement |
| --- | --- |
| Working color | sRGB, straight alpha; no premultiplied fringes |
| Raster edge | hard maximum 1024; no 2K/4K source committed |
| Character frame | 192×192 preferred, 128×128 minimum; transparent |
| Character atlas | target ≤800×800, hard cap 1024×1024 |
| Pixel art | forbidden; antialiased high-resolution forms |
| Naming | lowercase snake case: `<family>_<part>_<state>_<direction>_<variant>` |
| Pivot | integer pixel where possible; identical per module/state family |
| Godot filtering | linear for world/character; linear+mipmap only when downscaled |
| Compression | Lossless import for crisp masks/UI; VRAM/Basis only after target review |
| Repeat | disabled unless an asset is explicitly authored seamless |
| Source retention | editable source may live outside runtime; commit only approved exports |

## Character modules

Reference frame is 192×192, origin `(96,128)`, nominal avatar bounds `54×68`, in-game target
about 64 px high. Transparent padding covers Dash trails/limb rotation. Rigid modules use the
same pivot in every state; do not bake squash/stretch.

| Slot | Canvas | Local pivot / attachment | Safe visible bounds | Status |
| --- | ---: | --- | --- | --- |
| head | 64×48 | neck `(32,42)`; hat `(32,4)` | 28×20 | procedural integrated |
| hat | 64×32 | head hat `(32,28)` | 32×14 | registry-ready, hidden |
| torso | 64×64 | root `(32,30)`; neck `(32,7)` | 30×28 | procedural integrated |
| left/right arm | 32×64 | shoulder `(16,9)` | 10×22 each | procedural integrated |
| left/right leg | 32×64 | hip `(16,8)` | 10×22 each | procedural integrated |

Channels: body albedo mask, accent/emissive mask, neutral dark mechanics and optional outline
mask. No baked player color. Alpha must be binary-clean at silhouette edges after filtering.
Curated IDs are registered in `VisualAssetRegistry`; unknown/future profile IDs fall back to
base modules and are never interpreted as file paths.

### Required animation set

All time ranges are cosmetic guidance at 60 Hz; detached `PlayerAnimationMachine` state/events
remain the runtime source. Art completion never releases a gameplay lock.

| State | Frames / loop | Timing target | Pivot/invariant |
| --- | --- | --- | --- |
| Idle | 6–8 loop | 48–72 ticks | rigid micro arm/visor motion |
| Run | 8–12 loop | 18–34 ticks, speed-scaled | foot contact stable |
| Jump | 3–5 holdable | 8–14 ticks into hold | raised arms/tucked legs |
| Fall | 3–5 loop/hold | 18–30 ticks | open silhouette |
| DoubleJump | 6–8 one-shot | current 11 ticks | body rotation + ring |
| WallSlide | 4–6 loop | 24–36 ticks | mirror by wall side |
| WallJump | 4–6 one-shot | current 8 ticks | outward lean |
| Dash | 5–7 one-shot | gameplay Dash duration only | one base rotated to 8 directions |
| Landing | 4–6 one-shot | current 6 ticks | translation/limb bend, no scale |
| Death | 8–12 one-shot | current 27 ticks / 0.45 s | modules separate and fade |
| Respawn | 6–10 one-shot | current 15-tick visible hold | rebuild; halo follows invulnerability |
| FinishVictory | 6–10 loop | cosmetic | raised arms, no authority callback |
| Turnaround | 3–5 one-shot | current 4 ticks | follows Skid |
| Skid | 4–6 one-shot | current 5 ticks | precedes Turnaround |

Future `FastFall` art may reserve an enum/atlas row but must not create Fast Fall gameplay.
Dash direction order is E, SE, S, SW, W, NW, N, NE. Run playback speed follows horizontal
speed ratio. Max speed adds only a subtle three-line trail.

## Environment kit

| Asset | Dimensions | Use/import | Status |
| --- | ---: | --- | --- |
| `industrial_foundry_far_v1` | 1024×512 | WebP; linear; no mipmap; no repeat; drawn 2048×1024 at z=-100 | integrated generated |
| brutalist mass modules | 256×512 / 512×512 | optional future transparent cutouts; no collision cues | future |
| concrete/steel material swatch | 512×512 | seamless only if edge-tested; linear+mipmap+repeat | future |
| pipe/gantry silhouette strip | 1024×256 | transparent, low contrast, no walkable edge | future |
| grime/number decal sheet | ≤512×512 | transparent; no red/cyan route-like bars | future |

The far plate must keep its center/lower band quiet, avoid text/logos and tolerate crop at
16:9 without critical landmarks. Foreground/midground code-native geometry stays aligned with
collision. The map camera and fixed 1920×1080 logical frame are not changed to reveal art.

## Platforms

Platform assets are procedural/code-native in M23 so their visual bounds follow the existing
polygon without changing it. A future replacement uses a nine-slice/edge strip constrained to
the collision polygon and must expose these non-color cues:

| Type | Shape/motion cue | State variants |
| --- | --- | --- |
| Static | continuous top rail + rivets | normal |
| One-way | dashed rail + downward ticks | normal |
| Moving | opposed chevrons + physical movement | normal, optional endpoint pulse |
| Breakable | repeated fracture marks | solid, armed, ghost/absent, restored |
| Jump Pad | gold rail + diagonal energy marks + arrow | idle, contact pulse |

Collision polygon, one-way margin, route points, speed, waits, break/restore timers and launch
impulse are immutable under visual replacement.

## Hazards and race objects

| Family | Canvas/bounds | Required variants and pivot |
| --- | --- | --- |
| Spikes | exact configured rectangle | inactive hollow, amber telegraph, active filled; bottom-center pivot |
| Saw | diameter = collision diameter | toothed silhouette, hub, static/moving; center pivot; never exceed radius |
| Laser | exact configured rectangle | inactive channel, dotted telegraph, active core/end caps; center pivot |
| Turret | 96×96 base, ≤64×24 barrel | idle/aim/telegraph/fire/cooldown; base center, muzzle at barrel end |
| Projectile | ≤32×32 | pointed diamond/core/trail; center pivot; pool-owned |
| DeathZone | authored volume | edge/fall telegraph only; never decorate as safe floor |
| Start | 128×192 | twin gate/check band; bottom-center |
| Checkpoint | 128×640 authoring | inactive/activated; ground foot at existing marker; bottom-center |
| Finish | 160×640 authoring | twin uprights/check panel; bottom-center |

Telegraph, active and inactive states must remain legible at 30% remote-effect context and
under representative colorblind correction. Visuals never enlarge lethal/collision areas.

## VFX

| Effect | Canvas / lifetime | Policy |
| --- | --- | --- |
| Dash | 192×96 / gameplay Dash | three tapered lines; rotated in eight directions |
| Double Jump | 128×128 / 11 ticks | expanding ring + four radial ticks; flash-scaled |
| Max speed | 96×64 / while qualified | three subtle trails; speed-intensity-scaled |
| Death | 192×192 / 27 ticks | module disintegration, no full-screen flash |
| Respawn/invulnerability | 128×128 / 15 ticks + snapshot | thin halo; flash-scaled |
| Finish | 128×96 / cosmetic | restrained crown arc |
| Readiness | ≤12×12 | filled/hollow circle and square plus module emission |

Current avatar VFX use immediate draw calls and allocate no repeated nodes. Projectiles retain
the M9 pool cap of 10 global / 5 per target. Any future repeated sprite effect must use a fixed
pool, preload its texture and publish its cap in the manifest.

## UI, HUD and logo

UI remains Control/theme based at logical 1920×1080. Safe layouts are verified at 1280×720,
1280×800 and 1920×1080, RU and EN. Minimum body text is 20 reference px; primary button height
is 58; panel outer inset is 96 horizontal / 72 vertical; panel content inset is 28; vertical
rhythm is 12–16. Focus boundary is 3 px gold. Transitions are 200 ms (allowed 150–250 ms).

The integrated velocity mark is code-native, nominal 180×24, and contains no localized text.
Future wordmark export may be SVG with a 720×160 viewBox, outlined/embedded licensed type,
single-color fallback and no rasterized menu background. HUD remains text/shape based and
must respect text scale, UI scale and HUD opacity.

## Manifest and acceptance

`visuals/environment/asset_manifest.json` is tooling-readable provenance/budget inventory;
`VisualAssetRegistry` is the runtime allowlist. They deliberately have separate roles so JSON
or profile data cannot inject executable/resource paths.

Reject an asset if it exceeds dimensions, creates a false collision affordance, obscures an
avatar/checkpoint/hazard, relies on hue alone, changes route/timing/authority, adds a runtime
dependency, introduces visible generation text/watermark, or causes first-use loading.
