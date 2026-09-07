# M3 validation evidence

Environment: Windows, Godot 4.7.2.stable.official.ed1daf0bf, 60 Hz physics. Branch feature/m3-player-controller is based on approved dev 01a750d6a69ba5d9ed367101ebab198e22c948ad. Version 0.3.0-dev, build 4; save schema 2 and network protocol 1.

`powershell -ExecutionPolicy Bypass -File dev_tools/validate.ps1` validates the engine, imports all resources, checks individual GDScript parsers, runs M0 assertions, M1 (139 checks), M2 (124 checks), M3 motor/state tests (187 checks), and real CharacterBody2D physics tests (20 checks per replay). It boots the actual main scene with an isolated save and checks Git whitespace. No gameplay test reads a real profile/save.

The physics replay records 720 ticks of position, velocity and gameplay state. Hash at 30/60/144 FPS: a384c1104e7019e0fd04edd44be816c4db36c703d8d6440ec79f8bb1ff667277. The fixture covers flat ground/jumps, wall slide/jump, walkable/steep ramps and Dash against a wall. Equality is scoped to this engine/platform and input trace, not network lockstep or cross-platform bitwise guarantees.

Normal renderer smoke: `godot --path . --script dev_tools/player_presentation_smoke.gd`. OpenGL Compatibility / AMD Radeon Graphics successfully rendered the arena; screenshot inspected at builds/validation/m3-playground.png (ignored). No critical errors or parser warnings were reported. Final artwork and subjective movement feel are not validated by this screenshot.

CI runs the same complete suite plus an official-template Windows staging export and exported executable boot. CI results are attached to the M3 pull request; local export templates are absent, so exported-build acceptance is checked by CI. The staging executable intentionally retains the foundation main scene; the developer arena is excluded with dev_tools.

Physical gamepad testing was explicitly deferred by the developer because no controller is available. No new dependencies, networking, race mode, hazards, menus or later milestone implementation is included.
