# Testing checklist

Run dev_tools/validate.ps1 for the complete M0 + M1 + M2 + M3 suite; add -ExportWindows when matching export templates are installed. CI uses that switch on Windows.

## Automated

- [x] Exact Godot 4.7.2, full editor import and individual GDScript parser checks across core, gameplay, visuals, save_system, tests and dev_tools.
- [x] M0 assertions: 60 Hz, renderer/aspect, build/network identity, config, logging, translations and watermark.
- [x] M1 first-run profile persistence, UUID v4 format/uniqueness/stability, typed profile and full JSON round trips.
- [x] Valid/invalid nickname examples including Russian/Ukrainian Cyrillic, emoji, control characters and unsupported Unicode.
- [x] Language, colors, device, cosmetic slots, settings, records, splits and lobby defaults round trip.
- [x] Previous-known-good backup, malformed/missing primary recovery, both invalid → defaults and quarantine.
- [x] Root/version/required-field/value validation, oversized primary recovery and invalid writes.
- [x] Version 0 → 1 migration, identity preservation, pure migration input and persisted migrated schema.
- [x] Future schema read-only handling with/without backup and byte-for-byte preservation.
- [x] Staging/backup write failures preserve the only good primary.
- [x] Recovery translations for English/Russian; successful fixture cleanup.
- [x] Actual main-scene headless boot with isolated save initialization.
- [x] Git whitespace checks and no user saves/secrets staged.

Normal renderer smoke: godot --path . -- --smoke-test (bounded externally by the validation host). This uses a temporary save and exits after a physics tick. Headless success alone does not validate appearance or target hardware performance.

All tests use unique OS cache paths, never user://saves. Capture stdout/stderr; both exit codes and success markers matter. See docs/M1_VALIDATION.md for run evidence and CI handoff status.

## M2 input validation

- [x] Defaults, keyboard/pad profile separation, input-action presses/holds/releases and normalized vectors.
- [x] Deadzone filtering, eight Dash directions, selection persistence and explicit clearing without auto-fire.
- [x] Fresh Dash presses reuse held keyboard/stick aim after successful Dash clearing; held trigger/direction alone never auto-repeat.
- [x] Rebind conflicts/types, capture, reset, UI actions and prompt refresh.
- [x] Meaningful last-device activity, ignored drift, per-pad isolation and disconnect fallback.
- [x] Synthetic hotplug/reconnect and Godot joy_connection_changed signal routing.
- [x] Prompt families and persisted profiles/device; save migration v1→v2.
- [ ] Physical USB/Bluetooth controller hotplug and naming on target hardware (no controller connected).

Evidence: docs/M2_VALIDATION.md. No gameplay is required to run these tests.

## M3 movement validation

- [x] Valid/invalid tuning, fixed acceleration/deceleration, speed caps, rising/falling gravity and terminal velocity.
- [x] Variable jump apex, exact coyote boundary, extra jump consumption/refresh and no jump buffering.
- [x] Wall slide descent, outward/upward jump, steering lock and ability restoration.
- [x] All eight Dash directions, exact duration, locked vector, momentum/end lag, optional cancellation and no auto-fire.
- [x] Death, neutral respawn, invulnerability expiry and finish states; presentation independence and reversal sequence.
- [x] Real CharacterBody2D landing, double jump, wall contacts/jump, shallow/steep slopes and Dash collision/selection clearing.
- [x] Identical 720-tick body replay hashes at 30, 60 and 144 render FPS.
- [x] Normal OpenGL arena startup and screenshot via dev_tools/player_presentation_smoke.gd.
- [x] Developer keyboard playtest: movement, Double Jump and Dash work correctly.
- [x] Reset requires 60 uninterrupted physics ticks; short/released holds cancel and a continued hold cannot retrigger.
- [ ] Further movement-feel tuning and physical gamepad playtesting on target hardware.

Evidence: docs/M3_VALIDATION.md. The M3 fixture never opens SaveStore. Motor tests are pure and physics tests construct isolated geometry in memory.
