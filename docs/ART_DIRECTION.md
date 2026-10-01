# ProjectVelocity art direction — M23

## Visual pillars

1. **Readable velocity.** The player, route edge, hazard phase, checkpoint order and Finish
   are the highest-value information. Decoration never competes with them.
2. **Clean modular android.** The avatar is a compact, rigid, high-resolution 2D machine,
   not pixel art and never squash-and-stretch. Body color is identity; accent/emissive is
   readiness and action feedback.
3. **Industrial mass, restrained detail.** Foundry Run uses monumental brutalist concrete,
   steel bays and sparse services. Large value blocks establish depth; small grime/detail is
   confined to the far layer.
4. **Shape before hue.** Every platform class, hazard phase and race object has a silhouette,
   line or motion cue independent of colorblind correction.
5. **Presentation cannot become authority.** Art observes detached state and may be removed
   without changing physics, map order, hazard timing, networking or records.

## Palette and value hierarchy

Runtime constants live in `visuals/art_palette.gd`; exact values are shared by procedural
character, world and UI art.

| Role | Hex | Value / use |
| --- | --- | --- |
| Void | `#080D12` | deepest gaps and outlines |
| Background | `#0B1117` | far layer base |
| Panel | `#101B24` | UI and midground |
| Raised panel | `#172832` | interactive UI surfaces |
| Steel dark | `#26343D` | structural volume |
| Steel | `#44535C` | collision mass |
| Concrete | `#56626A` | foreground support |
| Route | `#78D8D2` | safe traversable edge / progression |
| Route dim | `#2E6B70` | secondary direction and depth |
| Focus | `#EDC675` | focus, Finish and exceptional route cue |
| Ready | `#B9FFE8` | confirmed ability/checkpoint state |
| Warning | `#FFBD59` | telegraph / temporary surface |
| Danger | `#FF405C` | active lethal state only |
| Text | `#E7F0F2` | primary text |
| Text muted | `#91A6AD` | secondary text |

Value priority is: avatar and active hazard core > route edge and race marker > UI text/focus
> collision mass > generated background > ambient detail. Bright white is reserved for tiny
cores/readiness, never large background areas. Red is not used as decoration.

## Scale and character readability

- Logical view remains 1920×1080; gameplay framing keeps the android near 64 px tall, within
  the 5–7% target. Authoring reference is a 192×192 transparent frame with a 64 px nominal
  in-game footprint and at least 24 px clear action margin.
- Head, torso, arms, legs and hidden hat attachment remain separate rigid nodes. Module scale
  stays `(1,1)`; rotation and translation carry poses.
- Head visor, torso chevron, limb marker and joint discs create three value breaks at target
  scale. Local outline is subtle; remote outline is absent/weak.
- Body/accent RGB is preserved. Local root alpha is 100%; remote root alpha/effects are 30%,
  applied once. Remote nickname inherits the same root alpha; local nickname is hidden.
- Head/arm/torso emission means Dash readiness; leg emission means extra-jump readiness.
  Filled circle/square cues mean ready and hollow cues mean unavailable. The Dash selection
  arrow remains local-only.

## Industrial + Brutalism kit

Foundry Run layers:

- **Far (`z=-100`)**: the integrated 1024×512 generated plate, drawn as dark 2048×1024 tiles.
  It supplies concrete bays, steel ribs and atmospheric depth only.
- **Background (`z=-10..-7`)**: authored massive section silhouettes, ribs and crossmembers.
- **Midground (`z<0`)**: muted pipes/couplers/signage and broad directional bands.
- **Gameplay plane (`z>=0`)**: collision silhouettes, route edges, platforms, hazards and race
  objects. These must remain visually dominant.
- **Foreground**: reserved for sparse edge framing that never occludes the avatar or route;
  none is added in the first pass.

The generated plate has no collision, input or process loop. It is selected by curated map ID,
not by a Resource path stored in map/profile data. Training Circuit receives no Foundry theme.
The fixed logical view/aspect bars remain authoritative; ultrawide gains no additional view.

## Gameplay grammar

- Static: continuous cyan top edge plus rivet dots.
- One-way: broken top edge plus downward ticks.
- Moving: bright continuous edge plus opposed chevrons; actual movement remains the main cue.
- Breakable/temporary: amber edge plus repeated fracture marks; armed/absent animation retains
  the existing fixed-tick state.
- Jump Pad: gold rail, diagonal energy marks and launch arrow.
- Spikes: repeated triangular teeth; inactive/telegraph are hollow, active is filled with a
  white contour. Saws use a toothed radial silhouette and hub. Lasers use end caps, channel,
  telegraph dots and an active bright core. Turrets use a faceted base, separately colored
  barrels and dashed locked target channels. Projectiles use a pointed diamond plus trail.
- Start uses a gate/check band; checkpoints use numbered-order-compatible diamond beacons and
  a filled activation core; Finish uses twin uprights and a check pattern. These are readable
  without a minimap or permanent checkpoint counter.

## UI/HUD language

Square brutalist panels, 2 px steel boundaries, cyan structural lines and a gold 3 px focus
outline define the M11-derived UI. The code-native velocity mark scales cleanly in RU/EN.
Buttons remain real Controls with keyboard/mouse/controller focus; no UI is rasterized.
Transitions remain 200 ms. HUD text receives a dark outline and respects text/UI scale and
50–100% HUD opacity. Online lifecycle/reconnect/results reuse the same theme.

## Accessibility and motion policy

High contrast and colorblind corrections remain a presentation shader applied after world
rendering. Shape grammar is always present so hue remapping is supplementary. Flash intensity
scales rings; `disable_strong_flashes` caps them. Speed trails honor speed-effect intensity;
camera shake remains in `LocalPlayerCamera`. No full-screen flash was introduced. VFX stays
behind race markers and never changes animation/gameplay duration.

## Budgets and conventions

- Hard texture/atlas edge: 1024 px; target character atlas: about 800×800; typical future
  frames: 128–192 px. Current character/world grammar is procedural and consumes no atlas.
- Integrated raster source: 1024×512 WebP, 22,444 bytes in git, estimated 2,097,152 decoded
  RGBA bytes. It is displayed enlarged, so linear filtering and no mipmaps/repeat are used.
- Repeated projectile nodes remain preallocated (10 global / 5 per target). Player VFX are
  immediate procedural draws with no per-use texture/resource load. The background texture is
  preloaded by its presentation class.
- Asset IDs use lowercase snake case with role/version suffix (`industrial_foundry_far_v1`).
  Runtime paths exist only in the curated registry. Profile cosmetic strings never execute or
  load paths. Generated raw/rejected variants remain outside the repository.

## Delivery split

Integrated first pass: procedural android refinement, platform/hazard/race-object grammar,
UI theme/mark, moderate action VFX and one generated Foundry far plate. Future replacement:
fully illustrated modular character sheets, additional biome kits, authored decals, final
typography/font licensing and audio. Future assets must satisfy the exact contract in
`ASSET_SPECIFICATION.md`; they must not alter gameplay to fit art.
