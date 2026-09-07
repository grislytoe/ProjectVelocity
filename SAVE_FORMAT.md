# Save format — M2

## Location and ownership

Current schema: **save_version 2** (SaveSchema.CURRENT_VERSION).
SaveStore defaults to user://saves, normally %APPDATA%/Godot/app_userdata/ProjectVelocity/saves on Windows. The application writes local data only; no cloud sync or upload exists.

| File | Purpose |
| --- | --- |
| save.json | Validated current JSON document |
| save.backup.json | Previous-known-good generation |
| save.tmp | Flushed and re-read proposed primary |
| backup.tmp | Flushed and re-read proposed backup |
| save.json.corrupt-UUID / save.backup.json.corrupt-UUID | Preserved corrupt input, never automatically deleted |

Transient staging files are not authoritative recovery inputs. A subsequent save may replace them. Saves must not be stored inside the repository. Files are UTF-8 JSON, bounded to 4 MiB on read/write.

## Schema fields

Every listed field is required. JSON integer-valued numbers are accepted as integers after parsing; booleans, fractions and non-finite values are rejected for integer fields.

| Field | Shape and constraints |
| --- | --- |
| save_version | Nonnegative integer; current version 2 |
| profile.uuid | Cryptographically random RFC 4122-style UUID v4, lowercase, generated at first profile creation |
| profile.nickname | 3–15 Unicode code points; rules below |
| profile.body_color / accent_color | Eight lowercase hexadecimal RGBA digits |
| profile.cosmetic_slots | String-to-string dictionary; head, hat, torso, arms and legs required; empty string means unused; values max 128 characters |
| profile.language | en or ru |
| profile.last_input_device | keyboard_mouse or controller |
| profile.created_at / last_launch_at | Positive Unix UTC seconds; last launch cannot precede creation |
| settings.video | resolution [width,height] (integer dimensions 320–16384), window_mode (windowed/fullscreen/borderless), vsync boolean, fps_limit (0/30/60/90/120/144/165/240), effects_quality (quality/balanced/performance) |
| settings.audio | master, music, sfx, ui, ambience volumes, each 0–1 |
| settings.controls.bindings | Action strings mapped to arrays of serialized binding strings (max 128 characters each); empty initially; legacy M1 foundation, retained without applying these strings |
| settings.accessibility | high_contrast boolean; flash_intensity and screen_shake 0–1; ui_scale 0.5–2; hud_opacity 0.5–1 |
| time_trial_records | Map ID → {best_time_ms: positive integer}; empty initially |
| checkpoint_splits | Map ID → {pb_run_ms: nonnegative integer array, best_segment_ms: nonnegative integer array}; empty initially |
| last_lobby_settings | round_count integer 1–10, map_id string up to 128 characters; empty map initially |

Customization, language and input-device selection are owned by profile, not duplicated in settings. Future cosmetic slots can be added to cosmetic_slots. Settings, records and split containers are persistence foundations only; no gameplay, map validation or video/audio settings application is implemented. Unknown fields are retained by SaveStore's dictionary migration path, but typed profile conversion projects the documented profile fields.

## Nickname and identity

PlayerProfileData accepts ASCII Latin A–Z/a–z, Cyrillic letters U+0400–U+0481 and U+048A–U+04FF, ASCII digits, ordinary space, underscore and hyphen. Whitespace-only nicknames are invalid. No trimming, normalization or uniqueness check silently changes a valid nickname. Emoji, control characters, combining marks, accented Latin, punctuation outside the whitelist and other scripts are rejected. Cyrillic combining signs U+0482–U+0489 are excluded.

Duplicate nicknames are allowed. UUID is the persistent identity; nickname is display data and must never become a networking identifier. Successful reloads and migrations retain UUID and created_at. Startup advances last_launch_at, clamped to created_at if the system clock moves backward. Recovery defaults create a new identity only when no supported valid profile can be recovered.

## Replacement and recovery

SaveStore.open() validates the primary and backup before accepting either. It records source (primary/backup/defaults), data, notification_key and read_only. Normal startup persists a first profile or updated last_launch_at.

1. Valid primary: load it. Before replacing it, stage, flush and re-read the new document, then stage and validate the old primary as the backup.
2. Invalid/missing primary + valid backup: load backup, expose SAVE_RECOVERED, quarantine any corrupt primary, then restore primary without replacing the good backup.
3. Both missing: create and persist defaults without a recovery notification.
4. Neither valid: preserve corrupt originals under unique quarantine names, create defaults and expose SAVE_RESET.
5. Unsupported future versions or unreadable files: use a supported valid primary/backup if available, otherwise session defaults; expose SAVE_UNSUPPORTED or SAVE_IO_ERROR and disable saving. Original files are not overwritten or downgraded.
6. Invalid in-memory changes: return false with SAVE_INVALID; good files remain unchanged.
7. Write/flush/rename failure: return false with SAVE_IO_ERROR; retain usable session data and existing good files.

Notification keys have English/Russian translations and are available to future UI. No settings/recovery menu is added. Notification state lasts until the next open() or a later error replaces it; it is not a persistent notification queue.

Replacement uses same-directory rename after flush and validation. The implementation never deletes a destination to force a failed rename. If backup staging fails, primary replacement is aborted. This is atomic-style replacement, not a universal power-loss/directory-fsync guarantee. Single writer/process is assumed; concurrent application instances are not coordinated. Quarantine files require manual support cleanup.

## Sequential migration

MIGRATIONS maps an integer source version to a one-step migration method. decode() repeatedly applies N → N+1 until CURRENT_VERSION, verifies progress at each step, then validates the final schema. A missing migration is unsupported; malformed migration output is invalid. Migrations copy input and preserve profile identity.

Version 0 is a documented **pre-release test fixture, never a shipped schema**: same structure as version 1 except last_lobby_settings is absent. Its migration adds default lobby settings and advances to 1. Disk tests verify migration and re-save. Future schema changes must add sequential migration steps, raise CURRENT_VERSION and include old-data fixtures; never assume version 1 is permanent.

## Tests

tests/save_foundation_test.gd uses unique OS cache directories and constructor-injected SaveStore paths. It never opens the default user save. M0 scene tests, render capture and --smoke-test also inject/create isolated stores. Successful test runs remove fixtures; interrupted processes may leave isolated cache directories for diagnosis.

## Version 2 input preferences

settings.controls.input is required and contains profiles.keyboard and profiles.gamepad (action → binding-token arrays), deadzones.movement/dash/activity (finite values 0.05–0.9), and prompt_family (auto/generic/xbox/playstation/nintendo/steam_deck). Empty profile dictionaries use defaults; overrides are independent and validated. See CONTROLS.md for token formats and API conflict handling. The old controls.bindings dictionary is retained verbatim as a legacy foundation; M2 uses the new explicit profiles.

The v1→v2 migration adds default input preferences without changing UUID, profile fields, settings, records, splits or legacy bindings. The existing v0→v1 step then chains through v1→v2. A version-1 save with malformed controls fails validation instead of crashing. InputPreferences batches writes for 0.5 seconds and flushes pending changes on exit. Device activity never writes on every frame. Read-only saves remain protected.
