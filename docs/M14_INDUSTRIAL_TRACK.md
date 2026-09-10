# M14 — Foundry Run / Литейный маршрут

Build **0.14.0-dev /20**, schema **5**, protocol **1**. Official ID
`industrial_foundry`, version **2**, PV-MAP-1. Normal difficulty; displayed duration
and par are 90 seconds. Human clean completion and subjective Normal acceptance
remain **open**. Automated input-driven completion is demonstrated separately below.

## Layout and rhythm

Eight identity-root section scenes, each 5200 world pixels wide, are placed at
`((section_number - 1) * 5200, 0)`. Entrance `(0,600)` and exit `(5200,600)` meet on
the 20-pixel grid. Major static rectangles, local point paths and explicit `next_id`
links are serialized in M13 resources. The 41,600-pixel course stays fully loaded.
The main route proceeds right; vertical passages have visible takeoff/landing surfaces.
Concrete joints, bolts, ribs, service pipes and different overhead section accents are
non-colliding presentation. Cyan upper edges identify stationary support; special
platform colors and hazard shapes retain the existing M8/M9 visual language.

The section plan was established before authoring: safe introduction, independent
application, then moderate combinations. Approximate design budgets were 8 / 9 / 12 /
9 / 10 / 11 / 10 / 9 seconds, with additional human decision time anticipated.
Measured values below replace those estimates as technical evidence.

| Section and purpose | Local route / introduced mechanic | Measured split interval | Recovery to local x=4900 |
| --- | --- | ---: | ---: |
| 1 Receiving yard — establish speed and rhythm | 80px crate at x1000; spikes x2000; short jump under duct x2860–3360; 320px pit x4200–4520 | 7.817s | 7.667s |
| 2 Gantries — deliberate landings | Lower floor y720; step x1840; one-way x2220/y480; upper concrete x2580/y360; temporary bridge; spikes and static saw | 7.983s | 7.833s |
| 3 Ventilation shaft — vertical control | Spikes x1100; wall x2500, top y180; wall slide and repeated wall jumps; descending landing shelves | 10.933s | 10.783s |
| 4 Transfer span — commit to the jump | Spikes; 920px gap x2360–3280 using jump, Double Jump and fresh right Dash; saw and timed spikes | 7.533s | 7.383s |
| 5 Crane hall — moving support | 1200px pit x2000–3200; wide shuttle with 340px travel; moving saw x4050; spikes | 7.817s | 7.667s |
| 6 Press lift — vertical launch and landing | Jump Pad x1810; upper deck y140; permanent laser x2420; stepped return and spikes | 8.017s | 7.883s |
| 7 Live line — combine reads and evasion | Locally triggered spikes x1050; cyclic laser x2200; cover x3000; two-barrel turret x3880/y390; spikes | 7.867s | 7.700s |
| 8 Dispatch — apply learned mechanics | Static saw, temporary bridge across x2100–2580, spikes and cyclic laser; safe finish apron | 7.583s | 7.933s |

Intervals are between actual trigger timestamps, not section geometric boundaries.
Start is `(120,566)`. Seven mandatory checkpoints lie at local `(180,388)` in
sections 2–8, with `(180,566)` respawns. Their 450px trigger volumes cover the route
and the express exit. Finish is section 8 local `(5040,100)`. All anchors have full
capsule clearance, stationary support and fatal-volume exclusion checked by M7.
Fall DeathZone starts at y1100, extends 6000px past both route ends and is 10000px
deep, so outward airborne movement or temporary invulnerability cannot cross a thin
fatal strip into endless falling. Camera bounds are `(-1000,-850,43600,2350)`;
the existing smoothed M5 follow keeps its approved framing and vertical tracking.

## One optional shortcut

The gold **Express Perch** in section 3 is a separate upper branch at
x1900–2140/y340. The main route runs underneath and uses the wall at x2500.
For the express route, jump around x1700, Double Jump around x1880, brake onto
the gold perch, then jump and Dash diagonally up/right over the shaft wall.
It returns to the main landing at x2800–3300, before checkpoint cp3 in section 4.
Missed height or direction drops the player back to the shaft floor, costing time;
the branch does not require an unsafe respawn or an irreversible choice.

The automated shortcut lands on ExpressPerch; the main run explicitly does not.
It saves **170 ticks / 2.833 seconds** overall in the measured pair. It skips the
wall-slide/wall-jump lesson on that optional attempt; the main route exercises both.
Every checkpoint remains mandatory and in order. M7 rejects Finish with any missing
checkpoint; both completed routes persist all seven IDs. No mandatory checkpoint
is relocated, disabled or made optional by the shortcut.

## Coverage matrix

| Required mechanic | Section / local position | Verification |
| --- | --- | --- |
| Acceleration | 1, Start → crate | Real movement from zero velocity; RUN events/input trace |
| Deceleration | 2, one-way → upper landing | Driver releases horizontal input until grounded; main-route frames contain neutral movement |
| Normal jump | 1, crate x1000 and spikes x2000 | JUMPED event; actual collision-free traversal |
| Variable jump | 1, duct/spikes x2910–3100 | Four held jump ticks followed by release; low passage traversed |
| Double Jump | 4, transfer span | DOUBLE_JUMPED event, no artificial refill |
| Wall Slide | 3, shaft wall x2500 | 31 observed WALL_SLIDE ticks on main run |
| Wall Jump | 3, shaft wall x2500 | WALL_JUMPED event; actual repeated contact/detachment |
| Dash | 4, x2780 over gap | DASH_STARTED/DASH_ENDED; original contact refresh rules |
| Static platform | All sections | Declared collision rectangles, grid/seam checks and real support |
| One-way platform | 2, x2220/y480 | Actual StaticPlatform contact with one_way config |
| Moving platform | 5, shuttle | Actual MovingPlatform landing; unmodified 160px/s module |
| Breakable platform | 8, x2340/y600 | Actual BreakablePlatform contact arms it; retry rebuilds state |
| Jump Pad | 6, x1810/y600 | Actual JumpPad contact and controller launch |
| Spikes | 1 static; 4 timed; 7 local trigger | Existing configs validate; clean routes cross all three arrangements |
| Static saw | 2 x4550; 4 x4210; 8 x1000 | Actual clean jump over fatal volume |
| Moving saw | 5 x4050, vertical 140px path | Actual Double Jump clearance with moving hazard active |
| Permanent laser | 6 x2420/y100 | Actual jump over beam on upper deck |
| Cyclic laser | 7 x2200; 8 x4070 | Active phase clock and native warning; actual traversal |
| Turret | 7 x3880/y390 | Native channels/telegraph/projectiles; maximum one live projectile observed |
| DeathZones | Pits, y1100+ | Native fall zone present; M7/M9 fatal/lifecycle fixtures and recovery tests |
| Multiple checkpoints / Finish | Start + cp1–cp7 + Finish | Actual ordered trigger splits and validated Finish; negative skip cases |

The final map requirement list in master §20 does not require the future conveyors,
portals, boost pads, gravity or force zones; none are introduced. M8 slope support
remains covered by the existing platform fixtures and is unchanged.

## Reproduction and evidence

Run from `C:/Godot Projects/ProjectVelocity` using Godot 4.7.2:

```powershell
./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe
# Standalone route checks (Start → real PlayerController → validated Finish):
C:/Godot/Godot.exe --headless --path . --fixed-fps 60 --script tests/industrial_route_test.gd
C:/Godot/Godot.exe --headless --path . --fixed-fps 60 --script tests/industrial_route_test.gd -- --shortcut
C:/Godot/Godot.exe --headless --path . --fixed-fps 60 --script tests/industrial_route_test.gd -- --recovery
# OpenGL run with gameplay-resolution captures:
C:/Godot/Godot.exe --path . --fixed-fps 60 --script tests/industrial_route_test.gd -- --capture
```

PowerShell callers that need exit codes must use the waiting Start-Process pattern
in validate.ps1. Logs, replay samples, timing JSON and captures go only to ignored
`builds/m14`; each test creates a unique OS-cache SaveStore and deletes its test save.
The committed route driver is the deterministic input recipe. It reads position and
ground contact to issue movement/jump/Dash intent; it never sets position, velocity,
abilities, invulnerability, hazard phases or movement tuning. Solo's actual clock,
barrier, checkpoint triggers, lifecycle and record persistence remain authoritative.

Main: **3933 ticks / 65.550s**, zero deaths, seven checkpoints and saved valid PB.
Splits: **469, 948, 1604, 2056, 2525, 3006, 3478** ticks.
Shortcut: **3763 ticks / 62.717s**, zero deaths; splits
**469, 948, 1436, 1888, 2356, 2838, 3309**.
Main input digest at 30/60/144 render rates:
`099130fa102a2d903ba1b79c75b32b46310281f160b0d7dab49d165e86beaa4a`.
Shortcut input digest:
`db6d91aacabb30c9d12b596e293e9d96d47699512e7ade6499c701df30576042`.

Recovery is a separate **7821-tick** attempt with exactly eight ordinary lifecycle
death requests, one at local x4900 in each section. Each request uses `player.die()`
with normal invulnerability rules, never force-death or a relocation. The driver then
replays that section from the actual respawn and measures clock ticks until crossing
the same x again: **460,470,647,443,460,473,462,476**. This includes the 27-tick death
sequence, respawn and acceleration. It is a controlled late-section loss measurement,
not a claim about the distribution of human mistakes or every possible early death.

`industrial_map_test.gd` separately tests structural mutations, checksum/camera
identity, every missing checkpoint, capsule safety, each checkpoint's actual death/
respawn, obstructed-checkpoint fallback, pause/clock eligibility, independent PB,
old Training PB retention, retry/node stability and real AppUI selection/unload.
Its deliberate fixture relocations are not clean-run evidence.

Full local M0–M14 validation passed, including parser/import, isolated bootstrap,
M13 inherited signal-binding/local-coordinate negatives and 30/60/144 replay equality.
Windows OpenGL/AMD Radeon normal rendering completed the full route without errors;
key section captures at a 1280×720 world render target (1280×800 selection, fixed
16:9) were inspected for landing/hazard/shaft readability. This is not Steam Deck
or low-end target certification. Timed Node physics callbacks on this host were
approximately 0.29ms at p95 and below 10ms maximum in the measured validation run;
these brackets exclude renderer and physics-server work outside Node callbacks.
Loading/validation cost is paid before player control, not on first ability use.

## Iteration notes and identity

Real route tests drove these geometry changes: widen the one-way landing; position
the upper step within a full jump; provide explicit moving-platform landing; clear
the permanent beam from the Jump Pad landing; reserve separate floor space for the
Jump Pad so coplanar floor collision cannot swallow its contact; use a 120px cyclic
beam with normal-jump clearance. Original player/hazard/platform module configs and
turret projectile speed **1224px/s** remain unchanged. No timer or waiting gate pads
the course duration. Wall-climb braking/landing inputs are actual route actions.

The catalog now lists Foundry Run and Training Circuit. The latter retains its exact
three section scenes and short regression purpose. Because PV-MAP-1 conservatively
hashes catalog/gameplay code, and authored camera fields now participate in identity,
Training publishes version **3** with a new checksum. Existing version 1/2 records
remain on disk under their original keys; no PB is deleted or silently relabeled.
Schema stays 5. A test explicitly retains the approved M13 version-2 checksum record.

Author with the ordinary section scenes, or optionally regenerate the serialized
layout using the dependency-free offline `node dev_tools/author_industrial.cjs`.
That script is developer tooling, not runtime map generation. After intentional
edits, import and run `check_trial_hash.ps1 -Update`; it bakes both official entries
through MapDefinition.checksum and still rejects invalid structure.

## Required human review before merge

1. Open this main project folder in Godot. F5 → New Game → Solo → Map Select →
   **Литейный маршрут / Foundry Run**. Training Circuit remains a separate card.
2. Dismiss the hint or wait, observe 3/2/1/GO, then finish the main route without
   deaths or developer commands. Use the one-way steps, wall jumps, airborne Dash,
   moving-platform landing, held Jump Pad launch plus another jump and upper beam.
   Confirm the final result has zero deaths and a local PB.
3. Assess Normal difficulty, camera comfort, gradual learning, telegraph readability
   and the human clean time. These subjective criteria have not been manually accepted.
4. Retry and use the gold Express Perch in section 3. Confirm a useful saving and that
   the next checkpoint and Finish still validate. Test failed entry recovery to shaft.
5. Die in each section; check safe stationary respawns, continuing clock and typical
   lost progress. Pause/resume; hold R for 0.5s and keep holding to confirm one restart;
   release and retry. Check Results → Retry / Map Select / Main Menu repeatedly.
6. Inspect RU/EN, keyboard/controller, 1280×800 and fullscreen settings, and return to
   the 22-station playground / Training Circuit. Hardware/Steam Deck acceptance is
   separate. No merge or M15 start is authorized by this checklist.

### M14 review — compact Map Select (build 20)

Map Select now uses 96px rows with a map name and personal best on the left and
a 240px preview on the right. Description, difficulty, timing and technical metadata
are omitted. Five rows and Back fit at the default UI scale; enlarged accessibility
settings retain scrolling. The integration fixture checks five entries without adding
placeholder maps to the production catalog. Map versions/checksums and PB keys are unchanged.

### M14 review — grounded checkpoint markers (build 19)

Industrial version 2 lowers checkpoint origins from y100 to y388. The existing
M7 visual has its foot at local y212, so every marker now meets the y600 floor.
Checkpoint trigger height returns to the standard 450px; respawns stay at y566.
Start and Finish are unchanged. Version-1 records remain under their original keys.
