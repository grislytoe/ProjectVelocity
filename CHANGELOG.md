# Changelog

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
