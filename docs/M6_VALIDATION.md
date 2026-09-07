# M6 validation evidence

Base: approved merged M5 dev `9959b2c21a0bdd27796b792a5e5fefbab85c52f6`. Branch `feature/m6-test-playground`. Windows / Godot `4.7.2.stable.official.ed1daf0bf`, physics 60 Hz. Build `0.6.0-dev` / 7; save schema 2 and network protocol 1 unchanged.

The complete validator passes import/parser checks, M0, M1 (139), M2 (142), M3 motor (187), held reset (6), M4 (75), M5 (45), and M6 (157 checks per run at 30/60/144 FPS). M6 exercises actual station collision geometry, every catalog entry, all eight Dash directions, reachable double/wall-jump platforms, air reversal, variable jump, coyote ledge, terminal fall, slope seams/steep sliding and high-speed stopping at an 8 px wall. Navigation, fresh geometry, camera bounds, temporary state reset, developer lifecycle/refill/collision commands, localized hints, export exclusion and station-specific reset are also covered. Input edges advance after actual physics ticks, independent of render frame batching.

Existing 720-tick controller replays (20 checks each) remain identical at 30/60/144 FPS, with/without camera and without presentation. Gameplay hash: `a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277`. Camera hash: `6640203a07124a35289a00f60d7ab13cb80403f550082bded7a9dea172944fc4`. Headless main boot succeeds with isolated save storage. No movement tuning or authority code was changed.

Normal OpenGL Compatibility / AMD Radeon Graphics startup passes through six stations with Russian HUD. Captures under ignored `builds/m6-station-*.png` verify presentation, rulers, station hints and readable diagnostics at 1280x720. M6 smoke produces `PROJECTVELOCITY_M6_RENDER_OK` with no Godot warnings/errors. Human acceptance of the new station navigation, particularly physical D-pad operation, remains open; existing keyboard/gamepad movement was accepted during prior milestone review.

CI runs the full validator plus Windows staging export and executable headless boot using official engine/templates. Consult the M6 PR checks for the remote result. Local export templates remain unavailable, so export evidence comes from CI. Development scenes/tests remain excluded from exports; F5/main is unchanged. No real user profile is accessed by M6 tools/tests, and no save, credentials, cache, screenshots or logs are committed.

The pre-existing editor formatting/default normalization of `project.godot` is preserved locally; only the intended build-version update is staged. M6 contains no network synchronization implementation, future hazards, later milestones or automatic merge.
