# M7 validation evidence

Base: approved unmerged M6 7e5986d1b842e02ce70acc7369d109d7ba486df3. Branch feature/m7-checkpoints-death-finish. Build 0.7.0-dev / 8, Godot 4.7.2.stable.official.ed1daf0bf on Windows; fixed physics 60 Hz. Save schema 2 and protocol 1 unchanged.

Full dev_tools/validate.ps1 passed: GDScript import and every parser check, M0 bootstrap, M1 saves (139), M2 input (142), M3 motor (187), held restart (6), physics replays, M4 presentation (75), M5 camera (45), M6 playground (157 per render rate), isolated main boot, and M7 (47 checks per run at 30/60/144 FPS). No real-user profile paths are opened. Git staged/unstaged whitespace checks pass.

M7 checks cover malformed course/roster data, per-player strict and unordered progress, mandatory vs optional Finish, idempotence, ready withdrawal, authoritative GO, blocked controls, safe capsule clearance/static support, moving support and fatal overlap rejection, 27-tick disintegration, respawn reset and 45-tick immunity, unsafe checkpoint fallback, fully blocked recovery/retry, persistent DeathZone overlaps, and real checkpoint/Finish Area2D entry by two independent players.

Unchanged movement replay hash: a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277. Unchanged camera hash: 6640203a07124a35289a00f60d7ab13cb80403f550082bded7a9dea172944fc4. Presentation removal and camera presence still preserve movement.

Normal OpenGL Compatibility / AMD Radeon Graphics smoke passed the same integration sequence plus screenshot capture (48 checks), without warnings or errors. The Russian HUD and fixture image were inspected at builds/m7-lifecycle.png (ignored artifact). Human feel/gamepad and Linux/Steam Deck testing remain open. Local export templates are unavailable; GitHub CI is responsible for Windows staging export and executable boot. Consult the stacked M7 PR checks for the final remote CI result.

Manual scene: dev_tools/lifecycle_playground.tscn (F6), also reachable through the M7 button in the unchanged twelve-station M6 scene. Main/staging still uses the foundation scene. M7 adds primitives only, not race timing, records, results, platforms or networking. M6 PR #7 and dev are not merged or modified by this work. The unrelated project.godot normalization in the original checkout is untouched.
