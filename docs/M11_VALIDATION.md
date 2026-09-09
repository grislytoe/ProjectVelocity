# M11 validation evidence

Date: 2026-09-09. Engine: 4.7.2.stable.official.ed1daf0bf.
Build: 0.11.0-dev / 13. Save schema: 4. Protocol: 1.
Workspace: C:/Godot Projects/ProjectVelocity; branch feature/m11-ui-foundation.
Base: approved dev dd24e563ed3059ae594833622e34b252597fe663 (M10 PR #11).

## Automated regression

Full dev_tools/validate.ps1 completed M0–M11: import, every script parser, isolated F5
headless boot, persistence/input tests, motor/restart/presentation, camera, 22 playground
stations, lifecycle fixture, platforms/hazards and Time Trial replays at 30/60/144 FPS.
The validator reported its final success marker. Earlier M10 migration assertions were
updated from literal schema 3 to CURRENT_VERSION; their UUID/data assertions remain.

Unchanged replay expectations:

- M3 gameplay: a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277
- M5 camera: 6640203a07124a35289a00f60d7ab13cb80403f550082bded7a9dea172944fc4
- M8 platforms: 0e2e98ba055b78b3f98571fd8f89a3ed75494a959c049de447bcbf57cfb871dd
- M9 hazards: 6ccebac3b8552e612ba623e09692c3855e0bcda60d8958a517b3607db01599d1
- M10 trial: a2fa3ee3f37a1f2ab92cdbc8a136df014654988280d01c68ee11cffc0adcac36
- Baked gameplay content: 0832bd598cd2e34e22ca69967a1204871f89393d241386f46db1735606ef2072

M11 checks cover explicit first-run and actual relaunch, v3 migration, invalid Unicode,
valid Cyrillic/Latin names, UUID stability, canceled drafts, read-only and actual rename
failure, primary preservation and other save sections. They exercise Godot GUI keyboard,
mouse and simulated controller events across onboarding, forms, all front-end routes,
exclusive text entry/cancel/focus restoration, disabled entries, RGB live preview and
saved gameplay appearance. A controlled hardware-query fixture verifies entry release
blocking, stale-action clearing and fresh input after release. Repeated panels/transitions
retain stable node/connection ownership. Back/Confirm during transitions is guarded.
All tests use unique OS-cache SaveStore paths, never the production user save directory.

## Normal renderer and visual review

Local renderer: OpenGL Compatibility, AMD Radeon Graphics. The UI integration script
also runs through the real GUI/rendering pipeline, with captures for RU/EN splash,
language, onboarding, keyboard, menu, Profile, customization, New Game, maps, Settings,
Controls, Online placeholder and Level Editor. Window targets: 1280x720, 1920x1080 and
1280x800 (the latter retains the competitive 16:9 canvas; this is not Steam Deck hardware).
Screenshots are local ignored builds/m11-*.png and are not committed.

Visual review corrected robot bounds, reduced customization/map vertical space, kept
focusable forms within the scrolling layout and hid gameplay HUD behind modal screens.
Text and focus outlines remain readable in both locales. Capture tests persist each
selected locale before Cancel so screenshots represent real application language flows.
GPU tests wait for actual transition completion and run sequentially to avoid competing
OS windows stealing focus. These are GUI integration tests, not physical gamepad tests.

The updated dev_tools/time_trial_smoke.gd uses the new menu path and actual GUI Confirm,
then drives the existing motor to Finish: 354 ticks, 0 deaths. It captures hint/countdown,
GO/run/results (RU/EN), Retry, pause and controller prompts, with an isolated save.
No course movement tuning, death/pause timing, restart duration or record hash changed.

## Delivery and remaining manual review

CI is configured for the full validator plus official-template Windows staging export
and isolated exported boot. Local export templates are absent; CI result is checked on
the PR rather than claiming a local export. Logs/PNGs/exports/saves are ignored.
The unrelated project.godot editor normalization remains local; only the build version
change is staged for that file. Review and merge are explicitly reserved for the user.

Physical controllers, controller families, Linux/Steam Deck and subjective gameplay/art
review remain manual. Online, general settings application and production Level Editor
are later milestones and honestly unavailable. Main launch: open project.godot in this
same folder, F5, finish onboarding, New Game → Solo → Training Circuit. Full manual steps
are in TESTING_CHECKLIST.md. Do not start M12 or merge this milestone automatically.
