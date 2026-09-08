# Test Playground (M6)

Run `godot --path . dev_tools/test_playground.tscn`, or open that scene and press F6 in the editor. F5/main remains the foundation scene. This is an offline developer tool using default input bindings, the approved M3 controller, M4 presentation and M5 camera. It never loads or writes a player profile.

## Stations

Exactly one station is loaded. Coordinates and rulers are in world pixels; vertical ruler labels measure height above y=500. Change the catalog in `dev_tools/playground_station.gd` to add geometry without changing movement code.

| Station | Independent experiment | Reference / expected result |
| --- | --- | --- |
| 01 Ground | Accelerate, release, reverse | 680 px/s maximum; distinct braking and acceleration |
| 02 Air | Jump, steer, release, reverse across gap | Air acceleration/braking; lower landing platform at x=750 |
| 03 Variable Jump | Compare a tap against holding Jump | Held jump rises higher; HUD peak rise resets per attempt |
| 04 Coyote Time | Leave x=300 ledge, then jump | Six-tick grace; extra jump remains available; lower catch floor |
| 05 Double Jump | Jump right, press again near first apex | Platform is 270 px above floor, unreachable with one ordinary jump |
| 06 Wall slide | Start next to wall and release movement | Descending wall contact, capped at 100 px/s |
| 07 Wall jump | Jump away from wall toward left platform | Outward impulse and nine-tick steering lock |
| 08 Dash | Jump, aim with movement and press Dash | All eight directions; nine-tick Dash, end lag and momentum; contact refills |
| 09 Terminal velocity | Allow free fall | Reach 1400 px/s before landing; 2950 px initial center-to-floor drop |
| 10 Walkable slope | Traverse ramp both ways | 26.6 degrees; continuous floor contact across entry/exit seams |
| 11 Steep slope | Start over slope and descend | 63.4 degrees; sliding rather than ordinary grounded walking |
| 12 High-speed lane | Run/Dash across ruler marks into end wall | 6000 px usable lane; 8 px wall at x=5600 must stop the body |

The speed lane is a reusable future synchronization fixture only. M6 adds no network authority, replication, hazards, checkpoints, moving platforms, one-way platforms or race logic. Add isolated stations for those features when their implementing milestones are approved.

## Developer controls

- Movement / Dash direction: WASD or left stick. Jump: Space / bottom face button. Dash trigger: Shift / RB/R1; each attempt requires a fresh trigger, while direction can remain held.
- Previous/next station: PageUp/PageDown or D-pad left/right; wraps at ends. Mouse buttons and the station dropdown provide direct navigation.
- Hold R / top face button for one continuous second: reset to the current station spawn. Triggers once per hold; release rearms. Exiting the station envelope returns immediately.
- F6: force death (bypasses respawn invulnerability). F7: immediate respawn. F8: restore extra-jump and Dash charges only; does not skip active Dash/end-lag timers. F9: toggle collision drawing. Mouse buttons mirror these commands.
- F6 above means inside the running scene; editor F6 launches the selected scene. No controls are added to production InputBindings or persisted settings.

Diagnostics show movement state, world position, velocity, floor/wall contact, ability charges, coyote/Dash/wall-lock/end-lag ticks, station elapsed physics ticks, peak horizontal/fall speed, peak rise relative to the station spawn, and reset hold progress. Timers are physics ticks at 60 Hz. Peaks reset on navigation/respawn and are sampled once per physics tick, not used as gameplay authority. Readiness visuals and Dash direction indicator remain the existing M4 presentation. UI labels and station hints have English/Russian translation keys.

## Isolation and extension

`TestPlayground` queues UI navigation/actions and applies them before player simulation. It replaces the old collision subtree synchronously between physics steps, clears transient input, resets controller state, changes map bounds, then teleports with the existing interpolation-safe relocation signal. A single player/input layer/camera is reused. The catalog has stable IDs, spawn positions, collision rectangles/polygons and a recovery/camera envelope; grid labels and Dash guides have no collisions. Production tuning Resources remain unchanged.

All implementation files live in `dev_tools`, already excluded from staging exports; the scene also rejects non-debug execution. Tests live in `tests`, likewise excluded. M6 is deliberately not a production map or main-scene replacement.

## Validation

`./dev_tools/validate.ps1` runs M0–M6, including `tests/test_playground_test.gd` at 30/60/144 FPS. M6 assertions use real collision geometry and observe after player physics, so a rendered frame cannot accidentally repeat a pressed edge. They cover all stations, all eight Dash directions, thin-wall collision, navigation, camera bounds, state reset, dev commands, one-second reset, out-of-bounds recovery, export exclusion and localization. Existing motor tests cover precise timing/edge cases in greater depth.

Normal renderer smoke: `godot --path . --script dev_tools/test_playground_smoke.gd`. It captures six stations with Russian HUD into ignored `builds/m6-station-*.png`. Automated/synthetic D-pad navigation is not physical controller validation. See `docs/M6_VALIDATION.md` for recorded results.

M7 adds a button opening the separate dev_tools/lifecycle_playground.tscn fixture. The twelve original catalog entries, geometry, controls and tests are unchanged. Escape from M7 returns here. See CHECKPOINTS_AND_LIFECYCLE.md.
