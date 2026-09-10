# M13 validation evidence

Environment: Windows, Godot 4.7.2.stable.official.ed1daf0bf, Compatibility/OpenGL on
AMD Radeon Graphics; desktop 1920×1200. Main folder only:
C:/Godot Projects/ProjectVelocity. Base dev/origin/dev was
538b17e7efb3ee19ac200f573392bda870e8409b; baseline CI run 34395902406 succeeded.

## Completed local checks (2026-09-10)

- Full `./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe`: M0–M13 passed, including
  clean import, every GDScript parser check, isolated headless boot and all prior suites.
  The final run is in ignored builds/m13-validation-final.log.
- M13: **112 checks**. Single/multiple sections; catalog identity; null/empty definitions;
  duplicate IDs; broken links; missing direct/transitive dependencies; configs; grid,
  transform, overlap/seam/support, route/Start/Finish/checkpoint rules; declared hash
  mismatch; semantic reserialization/editor metadata/locale stability; changed hazards
  and dependent resources; repeated teardown and orphan-node count; physical unsafe
  Start rejection; real AppUI localized failure; schema-5 PB/UUID retention; nonstrict/
  optional routes and safe refusal of malformed record metadata.
- M10: **62 checks** at 30/60/144 FPS, including actual triggers/Finish, death clock,
  pause eligibility, quick restart, 12 repeated rebuilds and real UI round trips.
- Normal renderer `dev_tools/time_trial_smoke.gd`: menu/New Game/Solo/Map Select,
  hint/countdown, motor-driven complete run **356 ticks, 0 deaths**, both checkpoints,
  stored PB, RU/EN result, pause/retry and gamepad prompts. No engine errors/warnings.
- Normal renderer `tests/settings_runtime_test.gd`: passed with native=true, including
  minimum 1280×800, selected world-buffer pixel dimensions, fullscreen/borderless,
  16:9 camera framing, sharp UI, modal rollback and accessibility scales.
- F6 `dev_tools/map_framework.tscn -- --capture`: five examples rendered without
  warnings. Inspected grid/anchor/floor seam overview and rejected gap screen; no
  gameplay subtree remains on rejected examples. Captures stay in ignored builds/.
- Git whitespace checks passed. Tests use injected unique OS-cache stores; no real
  saves, credentials, caches, screenshots or logs are included in the commit.

## Baselines and map identity

All gameplay/camera replay hashes match the approved M10/M11 validation baseline:

| Trace | SHA-256 |
| --- | --- |
| M3 movement | a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277 |
| M5 camera | 6640203a07124a35289a00f60d7ab13cb80403f550082bded7a9dea172944fc4 |
| M8 platforms | 0e2e98ba055b78b3f98571fd8f89a3ed75494a959c049de447bcbf57cfb871dd |
| M9 hazards | 6ccebac3b8552e612ba623e09692c3855e0bcda60d8958a517b3607db01599d1 |
| M10 Solo | a2fa3ee3f37a1f2ab92cdbc8a136df014654988280d01c68ee11cffc0adcac36 |

The content identity intentionally changes: the old monolithic procedural course now
uses section Resources/scenes and a new canonical format. It is not a replay regression.
Training Circuit is `solo_training`, version **2**, PV-MAP-1 checksum
`57e1ae1fe0af3e7ae99ea6093dfcdd3821b2f62eb796afa0fb233a6e4040a232`.
Build **0.13.0-dev /16**, save schema **5**, network protocol **1**.
The user's unrelated project.godot editor normalization remains unstaged; only the
intentional application version change is included.

## Remote/export gate and limits

Local export templates are absent. The CI workflow installs official pinned templates,
repeats full validation, exports Windows staging, boots it against an isolated save,
assembles the real map and compares its checksum to the editor's boot checksum.
Use the PR checks/artifacts for the exact remote commit and export result.

Structural validation covers the documented M13 translated-section/floor seam contract;
it does not prove arbitrary map traversability. The normal renderer proves the existing
Training Circuit direct route. Physical Steam Deck/Linux/controller hardware and target
performance certification are separate review items. No streaming, production editor,
Workshop, network transport, online validation or signatures are implemented.

## Manual review in the main folder

1. Open project.godot from C:/Godot Projects/ProjectVelocity, on feature/m13-map-framework.
2. F5 → New Game → Solo → Training Circuit. Dismiss hints, run both checkpoints to
   Finish; test death, pause, R held 0.5s, Retry, Map Select and reentry. Old version-1
   PBs remain stored but are not displayed as version-2 PBs.
3. F6 dev_tools/map_framework.tscn. Keys 1–5: valid multi, valid single, gap,
   missing anchor and checksum mismatch. Inspect rings and developer diagnostics.
4. Open Video: minimum 1280×800, fullscreen/borderless render resolution, Keep/Revert.
   Confirm Level Editor still says In Development. The old 22-station playground remains
   dev_tools/test_playground.tscn.
5. Review the PR into dev. Merge requires separate explicit user approval.
