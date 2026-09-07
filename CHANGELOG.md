# Changelog

## 0.5.0-dev — M5 local camera

- Reduced zoom excursions by 30% after camera comfort feedback: 1.15 → 1.105 and 0.85 → 0.895; neutral framing and follow timing unchanged.

- Developer-requested controls: movement and Dash aim share WASD/left stick, including rebindings; Shift/RB still trigger separately. Existing saved direction overrides remain readable but cannot restore separate aim.

- Configurable Camera2D follow with capped velocity look-ahead, exponential easing and 5–7% reference framing.
- Map bounds accounting for viewport/zoom; prioritized zone Resources for zoom, offset, look-ahead and temporary lock, with exit hysteresis.
- Matched player/camera physics interpolation, post-controller camera sampling and immediate respawn/resize snap.
- Camera unit/replay tests, developer zone fixture and rendered jitter measurement; approved movement traces unchanged.

## 0.4.0-dev — M4 animation and character presentation

- Detached visual snapshots and an optional presentation observer; gameplay replay is unchanged with all visuals removed.
- All 14 required cosmetic poses, modular beveled android parts, run cadence, reversal sequence, oriented Dash and short death disintegration.
- Profile-driven body/accent RGB, future slot metadata, 100% local / 30% opponent policy, nickname and outline framework.
- Readiness lights and shape cues, local-only Dash indicator, developer pose/color gallery and automated presentation tests.
- Save schema 2, protocol 1 and M3 movement behavior unchanged; no networking or later milestone gameplay.

## 0.3.0-dev — M3 player controller

- Fresh Dash presses reuse a continuously held keyboard/stick direction after selection is cleared; no direction release is required and no automatic Dash is queued.

- Manual keyboard review confirmed movement, Double Jump and Dash. Arena reset now requires one continuous second of holding R, triggers once per hold and rearms on release; six regression checks cover its timing.

- Data-driven typed CharacterBody2D with ground/air acceleration, variable jump, six-tick coyote time, one extra jump, wall slide/jump and eight-way Dash.
- Fixed-tick movement state machine, terminal velocity, walkable/sliding slopes and lifecycle APIs; no Jump Buffer or Fast Fall gameplay.
- Independent animation state machine and robot placeholder, local Dash indicator and isolated no-save arena with device-aware prompts.
- Motor/state tests and actual collision replays at 30/60/144 FPS alongside M0–M2; save schema 2 and network protocol 1 unchanged.

## 0.2.0-dev — M2 input and device layer

- Godot keyboard/gamepad action maps, physical-key defaults, independent profiles, capture/rebind/reset and deadzones.
- Eight-way Dash selection, intent snapshots, device detection/hotplug and generic/Xbox/PlayStation/Nintendo/Steam Deck prompt descriptors.
- Debounced preference persistence, save schema 2 and M1 migration; network protocol unchanged at 1.
- 124 input checks alongside M0/M1 regression suites; no gameplay or settings UI.

## 0.1.0-dev — M1 core data and save foundation

- Persistent UUID profile, nickname validation, colors, cosmetic slots, language/device and timestamps.
- Schema version 1 JSON, structural validation, sequential migration fixture, staged replacement, previous-good backups and recovery state.
- Data foundations for settings, records, splits and lobby defaults; no gameplay/UI.
- Isolated persistence tests and M0 regression validation, including save-aware smoke startup.

## 0.0.1-dev — M0 foundation

- Godot 4.7.2 project, 60 Hz physics, Compatibility renderer and fixed-aspect 1080p view.
- Layer directories, typed bootstrap config, build identity, DEV/STAGING watermark and local logging.
- English/Russian placeholder scene; no gameplay.
- Dependency-free bootstrap tests, bounded headless validation, Windows staging export and GitHub Actions baseline.
- Engineering, branch, dependency and architecture documentation.
