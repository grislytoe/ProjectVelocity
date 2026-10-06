# ProjectVelocity

Competitive high-speed 2D racing platformer, built with Godot **4.7.2 Stable** and typed GDScript.

Current staging candidate: **0.25.0-rc.1 / build31 / STAGING**, protocol5/wire4/save5.
Windows x86_64 and Linux x86_64/SteamOS-compatible portable packages are produced by the M25
release gate. They are unsigned review artifacts, not an approved release. Production Online is
honestly unavailable while the M19 EOS/Auth/Connect/Lobby/P2P gate remains blocked. See
[release checklist](RELEASE_CHECKLIST.md), [release notes](RELEASE_NOTES.md),
[staging instructions](STAGING_BUILD.md) and [manual QA](M25_MANUAL_QA.md).

The implemented standalone game includes versioned persistence, keyboard/gamepad abstraction,
data-driven movement and presentation, modular platforms/hazards, Solo Time Trial, Foundry,
settings/accessibility, transport-independent local network authority/series/reconnect foundations,
an art pass and performance tooling. See SAVE_FORMAT.md for persistence and
[PLAYER_CONTROLLER.md](PLAYER_CONTROLLER.md) for movement.

Open `project.godot` in Godot 4.7.2 and press F6/F5 to run the main scene. See [BUILD_AND_RUN.md](BUILD_AND_RUN.md) for reproducible validation and staging export.

To play M3, open `dev_tools/player_playground.tscn` and press **F6**, or run `godot --path . dev_tools/player_playground.tscn`. WASD selects movement and Dash direction, Space jumps, Shift triggers Dash, and holding R for one second resets. On gamepad, the left stick controls movement and Dash direction; RB/R1 triggers Dash. This developer scene uses default bindings and does not read/write a player save. F5 runs the M11 front end and Solo entry.

- [Architecture and directory map](ARCHITECTURE.md)
- [Coding standards](CODING_STANDARDS.md)
- [Test checklist](TESTING_CHECKLIST.md)
- [Known issues](KNOWN_ISSUES.md)
- [Next steps](NEXT_STEPS.md)

Primary targets: Windows x64, Linux x64, SteamOS/Steam Deck. M25 CI builds Windows and Linux
release-template staging packages independently, then downloads and re-verifies their hashes.
Physical Steam Deck and approved low-end certification remain blocked/pending.

M4 adds modular android poses, profile-driven body/accent colors, opponent opacity/nickname/outline policy and readiness cues. Open `dev_tools/character_gallery.tscn` with **F6** for the interactive pose/color sheet. The playable M3 arena also uses the new presentation. See [CHARACTER_PRESENTATION.md](CHARACTER_PRESENTATION.md).

M5 adds the local follow camera, smoothing/look-ahead, map bounds and camera zones. Open `dev_tools/camera_playground.tscn` with **F6** to inspect default, zoom and lock modes. The ordinary movement arena also uses the new camera. See [CAMERA.md](CAMERA.md).

M6 adds the dedicated [Test Playground](TEST_PLAYGROUND.md): open `dev_tools/test_playground.tscn` with **F6**. Twelve isolated stations cover existing movement, slopes and high-speed collision. Use PageUp/PageDown, D-pad left/right or the station dropdown to teleport. Diagnostics and dev-only death/respawn/refill/collision controls do not affect production saves.

M7 checkpoint/death/finish primitives are available in dev_tools/lifecycle_playground.tscn. See CHECKPOINTS_AND_LIFECYCLE.md for scope and manual controls. Main/staging boots the M11 front end.

M8 adds modular platforms and Jump Pads to stations 13–16 of the developer playground.
M9 adds the complete offline hazard set, independent turret channels and capped projectile
pooling in stations 17–22. See HAZARD_MODULES.md and docs/M9_VALIDATION.md.
See PLATFORM_MODULES.md for Resource authoring and WORKFLOW.md for milestone task/branch rules.

M10: F5 now starts the playable Solo Time Trial menu. See TIME_TRIAL.md for the full loop,
record rules and training course, and docs/M10_VALIDATION.md for test evidence.

M11: F5 starts splash and explicit language/nickname onboarding, then the techno-industrial
Main Menu with profile/robot preview, customization and New Game → Solo → map selection.
Settings retains Controls; Level Editor honestly displays In Development.
See [UI foundation](UI_FOUNDATION.md) and [M11 validation](docs/M11_VALIDATION.md).

M12: Settings enables Video, Audio, Controls and Accessibility with Apply/Cancel/defaults,
15-second display confirmation and persisted device profiles. See [Settings](SETTINGS.md).
Historical M12 UI note. Current runtime identity is listed at the top of this document.

## M16 Local Network

Two separate Godot processes can play host/guest on localhost, with authoritative collision,
guest prediction/reconciliation, opponent interpolation and replicated world/lifecycle state.
Launch commands, emulator profiles and limitations: [NETWORKING.md](NETWORKING.md).
Validation evidence: [docs/M16_VALIDATION.md](docs/M16_VALIDATION.md). No EOS/Steam integration.

M13 uses the shared MapDefinition catalog, structural validation and PV-MAP-1 checksum.
Training Circuit now publishes map version 3 and preserves older PBs separately; save schema remains 5.
F6: res://dev_tools/map_framework.tscn. See docs/MAP_AUTHORING.md and docs/M13_VALIDATION.md.

## M14

M14 adds Foundry Run / Литейный маршрут: an official eight-section Industrial + Brutalism course. F5 → New Game → Solo → Map Select. Automated clean main: 65.550s; express: 62.717s. Human review remains open. Training Circuit is retained separately. Route/evidence: docs/M14_INDUSTRIAL_TRACK.md.
