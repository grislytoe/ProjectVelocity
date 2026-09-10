# Changelog

## 0.13.0-dev — M13 Map Framework (build 16)

- Added typed map/section/placement/point Resources, configurable pixel grid, explicit
  entrance/exit anchors, floor seam/structure diagnostics and safe load failure.
- Migrated the real Training Circuit/catalog/Solo path to three authored section scenes;
  retained the M7 lifecycle, M8 platforms, M9 pools and all 22 developer stations.
- Unified map/PB hashing as PV-MAP-1 with semantic resources, normalized code bundle,
  editor-save stability and exported-PCK identity checks. Training map version is 2;
  old PBs remain stored separately. Save schema 5 and protocol 1 are unchanged.
- Added nonstrict/optional checkpoint record routes with ID-based deltas and compatible
  segment minima, isolated valid/invalid map tests, failure cleanup and F6 grid fixture.
- Production Level Editor remains In Development. No streaming, online checks or M14.

## 0.12.0-dev — M12 Settings (build 15)

- Fixed resolution selection in fullscreen and borderless: a real world render target
  scales independently of the native UI while preserving the competitive camera view.
  Mode changes retain the selected resolution; Keep/Revert covers render size too.
- Synchronized native window state with Godot Window and guarded expired confirmation dialogs.
- Raised minimum resolution/window size to Steam Deck's 1280×800; legacy lower values
  upgrade without resetting player data.
- Enabled localized Video, Audio, Controls and Accessibility pages with explicit
  Apply/Cancel/defaults transactions and separate keyboard/gamepad rebind profiles.
- Added 15-second Keep/Revert display preview with timeout, focus-loss, teardown,
  failed-apply and failed-write rollback; unconfirmed display data never reaches disk.
- Applied render caps, VSync, native window modes, aspect-preserving ultrawide framing,
  three visual presets, UI/text scale, HUD alpha, contrast/color correction and effects.
- Created five routed audio buses, independent levels/mutes and quiet UI/SFX placeholders;
  empty menu/level music and ambience slots reserve future final content.
- Migrated schema 4→5 while preserving UUID, onboarding, cosmetics, PBs and foreign data.
  Protocol remains 1 and gameplay content hash/replays remain unchanged.

## 0.11.0-dev — M11 UI Foundation (build 13)

- Added techno-industrial theme, splash, explicit onboarding, Main Menu profile/robot
  header, New Game/Solo maps, transactional Profile and live RGB customization.
- Added exclusive controller text entry, directed focus, focus restoration, device
  prompts, mouse navigation and guarded 200 ms transitions. Level Editor and Online
  are explicit In Development pages; future settings are disabled.
- Preserved real Solo hint/countdown/run/PB/result/pause/Retry loop and map identity;
  applied saved appearance to the M4 course robot on entry and retry.
- Migrated schema 3→4 with an explicit onboarding_complete marker; preserved UUID,
  records and settings, with rollback/error presentation on failed profile saves.
- Added isolated GUI/persistence integration tests and normal-renderer RU/EN captures.
  Protocol remains 1; no gameplay authority, tuning or content hash change.

## 0.9.0-dev — M9 Hazard Modules

- Review: increase turret projectile speed by 50% (816 → 1224 px/s; cap fixture 90 → 135).
  Opponent-target rounds match opponent opacity (30%); pool reuse restores local opacity.

- Reused M7 DeathZone/lifecycle for static/timed/local-trigger spikes, static/path saws
  and permanent/cyclic lasers with nonlethal warnings and reserved respawn clearance.
- Added independent dual-barrel per-player turret states, bounded velocity lead, LOS,
  warning direction lock, minimum cooldown and Resource-based weapon overrides.
- Added scene-owned pooled target-bound swept projectiles; configurable 5-per-target,
  10-global and 3-engaging-turret defaults, skip-with-cooldown semantics and teardown.
- Added six isolated playground stations with a neutral-input second actor and diagnostics;
  real collision/lifecycle/pool stress tests at three render rates. Save/protocol unchanged.

## 0.6.0-dev — M6 Test Playground

- Twelve isolated stations for all implemented movement mechanics, walkable/steep slopes and high-speed thin-wall collision.
- Developer teleport via dropdown, buttons, PageUp/PageDown and D-pad; station-specific held reset, force death/respawn/refill and collision drawing.
- Localized hints, non-colliding rulers, eight-direction guide and live movement/contact/timer/peak diagnostics.
- Real station integration at 30/60/144 FPS and normal-renderer smoke. No movement tuning, saves, networking or later mechanics changed.

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

## 0.7.0-dev — M7

- Add per-player ordered/optional checkpoint progress and mandatory Finish validation with localized feedback.
- Add reusable DeathZone and independently owned 0.45-second death recovery with static respawn validation, Start fallback, blocked-spawn retry and existing 0.75-second immunity/presentation.
- Add transport-free synchronized-ready tick gate and actor start barrier, isolated M7 fixtures and automated physics tests.
- Preserve M6 stations, movement/camera replays, controls, profile schema and protocol. Build 8; stacked PR targets unmerged M6.

## 0.8.0-dev — M8 Platform Modules

- Reusable static/one-way, path-moving, breakable/temporary and Jump Pad scenes with typed Resource configs.
- Fixed-tick route sampling with speed, point waits, reverse, looping and ping-pong traversal.
- Contact-driven warning/disappearance and clearance-aware optional restoration; controller-owned pad launch.
- Four appended playground stations; preserved M3 slope policy and moving-support respawn rejection.
- Physics integration and render-rate traces; build 9, save schema 2 and protocol 1 unchanged.
- Persist main-folder/separate-task workflow and user-only merge authorization in WORKFLOW.md.

### M8 manual review follow-up

- Prevent repeated Dash refresh during uninterrupted floor/wall contact; require detachment and new contact. Preserve Double Jump refresh.
- Increase checkpoint trigger height from 90 to 450 px upward and marker height fivefold; keep respawn anchors unchanged.
- Add pure-motor and real floor/wall regression checks plus airborne checkpoint activation coverage.

## 0.10.0-dev — M10 Solo Time Trial

- F5 now exposes Main Menu → Solo → Map Select → hint/countdown/run/results/retry.
- Fixed-tick race clock, complete-run PB checkpoint deltas, death count and pause.
- Half-second rebindable Quick Restart reconstructs the complete course and skips hints.
- Schema v3 validates UUID/map/version/hash-bound PBs and segment minima, migrates legacy
  data without promoting unverified records, and retains the previous PB on write failure.
- RU/EN results, keyboard/gamepad hints, basic control rebinding and isolated integration QA.
