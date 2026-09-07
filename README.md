# ProjectVelocity

Competitive high-speed 2D racing platformer, built with Godot **4.7.2 Stable** and typed GDScript.

M0 establishes the engineering foundation; M1 adds versioned persistence; M2 adds keyboard/gamepad input and device prompts. M3 adds a data-driven CharacterBody2D controller, separate movement/animation state machines and an isolated movement laboratory. No race modes or online services are implemented. See SAVE_FORMAT.md for persistence and [PLAYER_CONTROLLER.md](PLAYER_CONTROLLER.md) for movement.

Open `project.godot` in Godot 4.7.2 and press F6/F5 to run the main scene. See [BUILD_AND_RUN.md](BUILD_AND_RUN.md) for reproducible validation and staging export.

To play M3, open `dev_tools/player_playground.tscn` and press **F6**, or run `godot --path . dev_tools/player_playground.tscn`. A/D move, Space jumps, arrows select Dash, Shift triggers Dash, R resets. This developer scene uses default bindings and does not read/write a player save. F5 still runs the foundation main scene.

- [Architecture and directory map](ARCHITECTURE.md)
- [Coding standards](CODING_STANDARDS.md)
- [Test checklist](TESTING_CHECKLIST.md)
- [Known issues](KNOWN_ISSUES.md)
- [Next steps](NEXT_STEPS.md)

Primary targets: Windows x64, Linux x64, SteamOS/Steam Deck. Initial CI exports Windows staging only.

M4 adds modular android poses, profile-driven body/accent colors, opponent opacity/nickname/outline policy and readiness cues. Open `dev_tools/character_gallery.tscn` with **F6** for the interactive pose/color sheet. The playable M3 arena also uses the new presentation. See [CHARACTER_PRESENTATION.md](CHARACTER_PRESENTATION.md).
