# ProjectVelocity

Competitive high-speed 2D racing platformer, built with Godot **4.7.2 Stable** and typed GDScript.

M0 establishes the engineering foundation; M1 adds versioned persistence; M2 adds keyboard/gamepad input and device prompts. M3 adds a data-driven CharacterBody2D controller, separate movement/animation state machines and an isolated movement laboratory. No race modes or online services are implemented. See SAVE_FORMAT.md for persistence and [PLAYER_CONTROLLER.md](PLAYER_CONTROLLER.md) for movement.

Open `project.godot` in Godot 4.7.2 and press F6/F5 to run the main scene. See [BUILD_AND_RUN.md](BUILD_AND_RUN.md) for reproducible validation and staging export.

To play M3, open `dev_tools/player_playground.tscn` and press **F6**, or run `godot --path . dev_tools/player_playground.tscn`. WASD selects movement and Dash direction, Space jumps, Shift triggers Dash, and holding R for one second resets. On gamepad, the left stick controls movement and Dash direction; RB/R1 triggers Dash. This developer scene uses default bindings and does not read/write a player save. F5 still runs the foundation main scene.

- [Architecture and directory map](ARCHITECTURE.md)
- [Coding standards](CODING_STANDARDS.md)
- [Test checklist](TESTING_CHECKLIST.md)
- [Known issues](KNOWN_ISSUES.md)
- [Next steps](NEXT_STEPS.md)

Primary targets: Windows x64, Linux x64, SteamOS/Steam Deck. Initial CI exports Windows staging only.

M4 adds modular android poses, profile-driven body/accent colors, opponent opacity/nickname/outline policy and readiness cues. Open `dev_tools/character_gallery.tscn` with **F6** for the interactive pose/color sheet. The playable M3 arena also uses the new presentation. See [CHARACTER_PRESENTATION.md](CHARACTER_PRESENTATION.md).

M5 adds the local follow camera, smoothing/look-ahead, map bounds and camera zones. Open `dev_tools/camera_playground.tscn` with **F6** to inspect default, zoom and lock modes. The ordinary movement arena also uses the new camera. See [CAMERA.md](CAMERA.md).

M6 adds the dedicated [Test Playground](TEST_PLAYGROUND.md): open `dev_tools/test_playground.tscn` with **F6**. Twelve isolated stations cover existing movement, slopes and high-speed collision. Use PageUp/PageDown, D-pad left/right or the station dropdown to teleport. Diagnostics and dev-only death/respawn/refill/collision controls do not affect production saves.

M7 checkpoint/death/finish primitives are available in dev_tools/lifecycle_playground.tscn. See CHECKPOINTS_AND_LIFECYCLE.md for scope and manual controls. Main/staging still boots the foundation scene.

M8 adds modular platforms and Jump Pads to stations 13–16 of the developer playground.
M9 adds the complete offline hazard set, independent turret channels and capped projectile
pooling in stations 17–22. See HAZARD_MODULES.md and docs/M9_VALIDATION.md.
See PLATFORM_MODULES.md for Resource authoring and WORKFLOW.md for milestone task/branch rules.
