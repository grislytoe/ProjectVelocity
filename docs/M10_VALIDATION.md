# M10 validation — Solo Time Trial

Environment: Windows, Godot 4.7.2.stable.official.ed1daf0bf, OpenGL Compatibility on
AMD Radeon Graphics. Main folder only: C:/Godot Projects/ProjectVelocity.
M10 began at M9 bb3371f, then fast-forwarded to approved dev merge fb299ea.
M9 CI run 34254010465 succeeded. M10 PR targets dev; no M10 merge is authorized.

## Automated evidence

- Full dev_tools/validate.ps1 M0–M10: manifest check, import, every gameplay/core/UI/map/
  test/dev script parser, isolated headless bootstrap and Git whitespace checks.
- M10: 62 checks at each 30/60/144 render FPS, matching fixed-tick replay.
- Actual PlayerController, PlayerLifecycle, checkpoint and Finish volumes; hint/countdown/
  GO, locked movement, clock through death/respawn, pause, valid/invalid Finish, Quick
  Restart 29/30-tick boundary and one trigger per hold, 12 stable scene/signal rebuilds.
- Actual UI menu/map entry/pause/result state and repeated menu entry regression.
- First/improved/equal/worse PB, complete-run timestamps vs segment minima, reload,
  v2 disk migration/UUID retention, malformed data, actual staged replacement failure,
  read-only store and map version/hash/player identity separation.
- All fixtures use unique OS cache directories / injected SaveStore. Production saves
  are never opened by tests, normal-renderer smoke or bootstrap --smoke-test.

Current replay hashes (M9 review baseline retained):

| Trace | SHA-256 |
| --- | --- |
| M3 movement | a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277 |
| M5 camera | 6640203a07124a35289a00f60d7ab13cb80403f550082bded7a9dea172944fc4 |
| M8 platforms | 0e2e98ba055b78b3f98571fd8f89a3ed75494a959c049de447bcbf57cfb871dd |
| M9 hazards (530 checks) | 6ccebac3b8552e612ba623e09692c3855e0bcda60d8958a517b3607db01599d1 |
| M10 time/splits/deaths | a2fa3ee3f37a1f2ab92cdbc8a136df014654988280d01c68ee11cffc0adcac36 |

## Renderer and manual review

Normal-renderer dev_tools/time_trial_smoke.gd navigates the actual Solo button and drives
the real motor through the entire course with movement/jump/Dash input: 339 ticks (5.650s),
zero deaths. Captures in ignored builds/m10-*.png cover menu/map/hint/countdown/GO/run,
RU+EN results, pause and simulated Xbox hints. Inspected for clipping and readability.
The run is a short module demonstration, not final map pacing or a performance benchmark.

Local export templates remain unavailable. PR CI installs official verified templates,
runs the same validator and Windows staging export/isolated boot. Check the submitted
commit's push/PR checks for the remote export result; no local export claim is made.

Build 0.10.0-dev / 12; save schema 3; protocol 1. No dependencies or transport added.
Preserved user project.godot normalization outside the staged version bump.

F5 / core/bootstrap/main.tscn → Solo → Training Circuit → Ready (or wait 3 seconds).
Move right, jump the spikes, pass both cyan gates and evade the turret to the lime Finish.
Results show total/PB delta/splits/deaths, Retry, Map Select and Main Menu. Hold R/top face
0.5s for restart; Escape/Start pauses. Developer test_playground.tscn remains intact with
all 22 stations, existing M7 fixture and one-second developer reset.
Physical controller navigation/hotplug, subjective feel, Linux/Steam Deck and low-end
performance remain manual. Local PBs are not an anti-tamper/security system.
