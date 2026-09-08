# M9 validation evidence

Base: approved dev/origin/dev f01ce09d75fb0158a84300969f74ead24404712e (M8 PR #9 merged).
Branch feature/m9-hazard-modules, main folder C:/Godot Projects/ProjectVelocity only.
No worktree or duplicate checkout. Godot 4.7.2.stable.official.ed1daf0bf on Windows,
physics 60 Hz; build 0.9.0-dev / 10. Save schema 2 and protocol 1 unchanged.

## Automated coverage

Full dev_tools/validate.ps1 passes import, every script parser, isolated headless
foundation boot, all M0–M8 regressions, M9 at 30/60/144 FPS and Git whitespace checks.
M9 has 527 checks, including 50 pool fill/expiry cycles and 12 station teardown cycles.
No engine errors, warnings, ObjectDB leaks or resources-in-use warnings on completion.

- Actual DeathZone, static/timed/trigger spikes, local sensor enter/exit, static/path
  circular saws and permanent/cyclic laser collisions; full warning boundaries, phase
  offset, retraction, retrigger, invulnerability and persistent-overlap expiry.
- Inactive hazard respawn reservation and actual M7 invalid-checkpoint fallback to a
  clear static Start with restored abilities and 45-tick immunity. Existing M7/M8
  checks retain moving/temporary/pad support rejection and safe respawn retry coverage.
- Explicit distinct player IDs/actors with no physical input dependency; bounded roster;
  ordered detection/LOS/aim/warning/fire/cooldown; simultaneous barrels; independent
  barrel override timing; angular speed limit; velocity lead time/displacement bounds;
  minimum cooldown; blocker introduction/removal; range/death/Finish/start cancellation.
- Default five-per-target and ten-global projectile caps, independent configured global
  cap, default/configured engagement cap, four actual turrets contending and releasing
  slots. Cap skips enter ordinary cooldown, with no delayed shot when a slot becomes free.
- Swept projectiles cross the nondesignated actor, kill only their target, respect
  invulnerability, hit the designated capsule at 60000 px/s and stop at a 2px wall.
  A translated/rotated pool parent cannot rotate or offset their world-space collision.
- Same object reused for a different target with clean cast exceptions, IDs, velocity,
  lifetime and visibility; stable pool instance IDs, exactly ten nodes after stress;
  death/relocation/deletion and source destruction release rounds; entire station
  teardown frees pool objects and removes actor signal connections.
- All six real M9 playground stations, physical hazard-to-lifecycle respawn and live
  turret occupancy. M6 now checks 22 unique localized stations and navigation/reset,
  preserving all original geometry and new-contact-only Dash refresh behavior.

## Replays and renderer

The current M8 base was measured before implementation, rather than inferred from old docs.
M3 and M5 at 60 FPS with camera, and M8 at 60 FPS, produced these baseline hashes. The
full M9 validator reproduced them at 30/60/144 FPS, including no-presentation comparison:

- M3: a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277
- M5: 6640203a07124a35289a00f60d7ab13cb80403f550082bded7a9dea172944fc4
- M8: 0e2e98ba055b78b3f98571fd8f89a3ed75494a959c049de447bcbf57cfb871dd
- M9: c236672debc0ca01c367d9586ab632ad4464277ad944e7747536490ffb89be06

M9 trace records pool occupancy plus target IDs, world positions and remaining lifetime
of active rounds. It matches at 30/60/144 FPS and normal-renderer 60 FPS. Physics replays
are not a claim of cross-platform bitwise determinism or target-hardware performance.

Normal OpenGL Compatibility on AMD Radeon Graphics passes M9 integration.
hazard_playground_smoke.gd captures all six stations with Russian HUD; local ignored
builds/m9-station-16.png through -21.png were inspected for geometry/HUD readability.
Snapshots show target counts, cap skips and separate channel warning states.

## Delivery and manual review

No test constructs production SaveStore or touches real saves. User project.godot editor
normalization is retained locally; only its intentional config/version bump is committed.
Local export templates are absent. PR CI runs the full M0–M9 validator with official
Windows staging templates, export and isolated boot; inspect the submitted SHA's checks
for remote evidence. CI artifact names now identify M9. Staging still boots foundation.

Open C:/Godot Projects/ProjectVelocity/dev_tools/test_playground.tscn with editor F6,
select stations 17–22. WASD/left stick move and aim Dash; Space/bottom face jumps;
fresh Shift/RB triggers Dash; hold R/top face one second for one local reset until release.
PgUp/PgDn or D-pad left/right navigate; dropdown selects directly. In-game F6/F7 force
death/respawn, F8 restores abilities, F9 shows collision. Reselecting a station resets
hazards, second actor, leases and pool. M7 lifecycle fixture remains separately available.

Offline two-player authority and procedural visuals are intentional. Human gameplay feel,
physical gamepad follow-up, Linux/Steam Deck and low-end target performance remain manual.
See HAZARD_MODULES.md / KNOWN_ISSUES.md for authoring and simulation limits. No new
dependencies, network transport, save/protocol migration, M10 or automatic merge.

## M9 review — build 11

Developer requested 50% faster turret projectiles and opponent-matching transparency.
Default speed is now 1224 px/s; the deliberately slow caps fixture increases to 135 px/s.
Opacity is copied from the designated actor's presentation at launch (30% for opponent,
100% local), remains cosmetic and resets before reuse. Three new assertions cover speed,
opponent alpha and opponent-to-local reuse; updated M9 suite has 530 checks.
Current M9 hash: 6ccebac3b8552e612ba623e09692c3855e0bcda60d8958a517b3607db01599d1.
