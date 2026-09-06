# Testing checklist

Run dev_tools/validate.ps1 for the complete M0 + M1 + M2 suite; add -ExportWindows when matching export templates are installed. CI uses that switch on Windows.

## Automated

- [x] Exact Godot 4.7.2, full editor import and individual GDScript parser checks across core, save_system, tests and dev_tools.
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
- [x] Rebind conflicts/types, capture, reset, UI actions and prompt refresh.
- [x] Meaningful last-device activity, ignored drift, per-pad isolation and disconnect fallback.
- [x] Synthetic hotplug/reconnect and Godot joy_connection_changed signal routing.
- [x] Prompt families and persisted profiles/device; save migration v1→v2.
- [ ] Physical USB/Bluetooth controller hotplug and naming on target hardware (no controller connected).

Evidence: docs/M2_VALIDATION.md. No gameplay is required to run these tests.
