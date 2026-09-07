# M5 validation evidence

Base: merged M4 dev de891c43b14a2e4d26a3b80adb05546c016cf143. Branch feature/m5-camera. Windows / Godot 4.7.2.stable.official.ed1daf0bf, fixed physics 60 Hz. Build 0.5.0-dev / 6; save schema 2 and network protocol 1 unchanged.

The complete validator runs import/parser checks, M0, M1 (139), M2 (142), M3 motor (187), reset (6), M4 (75), and M5 (45 checks). M5 covers reference scales, exponential follow/look-ahead, clamping, zone priority/hysteresis/lock/zoom/exit, explicit target binding, respawn and interpolation configuration.

The real controller executes the same 720-tick sequence at 30/60/144 FPS with the camera. Camera hash: 6640203a07124a35289a00f60d7ab13cb80403f550082bded7a9dea172944fc4. Gameplay hash remains a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277, matching the approved camera-free M3 trace. Each replay includes 20 collision/lifecycle checks; the earlier no-presentation replay also remains part of the suite.

Normal OpenGL Compatibility / AMD Radeon Graphics: the 144 FPS motion smoke measured 0px peak-to-peak marker jitter over 32 frames while the player moved at ground maximum speed. Disabling only player interpolation in the explicit negative control produced 7px and the expected diagnostic failure. Default, zoom and lock screenshots passed 5–7% framing checks and were visually inspected. This evidence is scoped to these fixtures/platform, not every possible movement, display driver or frame stall.

CI runs the entire suite plus official-template Windows staging export and executable boot. See the M5 PR checks for results. Normal GPU captures are local checks; matching export templates are not locally installed. No real saves are read by camera tests/fixtures. The existing main-scene smoke injects isolated storage.

The user's pre-existing editor normalization of project.godot is retained locally; only build version and physics interpolation are included in the M5 project-settings commit. No M6, networking, gameplay tuning or automatic PR merge is included.

During review the developer confirmed physical gamepad input and requested that Dash aim share movement controls: WASD/left stick. The input suite was extended for shared diagonals, old arrows/right-stick no longer selecting Dash, rebind/prompt synchronization and legacy override preservation. Schema 2 stays unchanged. The new layout requires a follow-up manual check; it does not alter camera or movement simulation tuning.

Camera comfort follow-up: zoom_variation_strength defaults to 0.7, reducing deviations from base zoom by 30%. Default effective zone zooms are now 1.105 and 0.895. Three additional checks verify both directions and unchanged neutral framing (45 camera checks total).
