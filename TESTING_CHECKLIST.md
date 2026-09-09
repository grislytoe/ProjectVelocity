# Testing checklist

Run dev_tools/validate.ps1 for the complete M0–M5 suite; add -ExportWindows when matching export templates are installed. CI uses that switch on Windows.

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
- [x] Shared WASD/left-stick movement and Dash aim, diagonal input, movement rebindings, synchronized prompts and compatibility with saved separate-direction overrides.
- [x] Developer physical gamepad control check passed before the shared-aim layout update; hotplug/naming coverage remains separate.
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

## M4 presentation validation

- [x] Every movement state maps to its explicit pose; temporary extra jump/landing/respawn poses expire or interrupt cleanly.
- [x] Eight-direction Dash orientation, mirrored wall side, run cadence and rigid module transforms.
- [x] Detached snapshots cannot mutate the motor; deleting all presentation nodes leaves the 720-tick replay hash unchanged.
- [x] Profile color validation/copying, opaque material policy, unknown-slot fallback and invalid-profile preservation.
- [x] Local/opponent alpha, outline and nickname policy; opponents ignore local preselection.
- [x] Ability lights recover without replacing customized body RGB; gallery color/readiness controls use the same pipeline.
- [x] Normal OpenGL gallery and playable arena smoke captures, inspected at reference window size.
- [ ] Developer M4 pose/feel review and physical gamepad/target-platform checks.

See docs/M4_VALIDATION.md. Gallery and tests never open a production save.

## M5 camera validation

- [x] Default framing and zoom limits at 720p/1080p/1440p/2160p logical sizes.
- [x] Follow easing, velocity look-ahead caps, stop/reversal and viewport-aware bounds, including undersized maps.
- [x] Zone priority/ID ordering, hysteresis, offset, zoom transitions, temporary lock and restoration on exit.
- [x] Explicit local target, old-target disconnect, respawn snap and enabled engine interpolation.
- [x] Identical camera traces at 30/60/144 FPS; gameplay trace remains identical without the camera.
- [x] Normal-renderer moving marker: 0px jitter; intentional disabled-interpolation control: 7px (expected failure).
- [x] Default, zoom and locked fixture captures inspected with framing checks.
- [ ] Developer camera comfort review and physical gamepad/target-display checks.

See CAMERA.md and docs/M5_VALIDATION.md. Negative-control errors are intentional diagnostic evidence, not part of the standard suite.

## M6 Test Playground

- Run `./dev_tools/validate.ps1`: all prior checks plus real M6 station integration at 30, 60 and 144 FPS.
- Open `dev_tools/test_playground.tscn` and follow each station hint; compare tap/held Jump, late ledge Jump, the elevated Double Jump platform, wall slide/jump, eight Dash directions, terminal velocity, both slopes and high-speed thin-wall stopping.
- Verify PageUp/PageDown, dropdown, mouse buttons and D-pad navigation; confirm respawn restores the active station with no camera sweep or leftover collision geometry.
- Hold reset less than one second, then a full second, then keep holding. Only the complete first hold resets; release rearms. Check F6/F7/F8/F9 developer actions.
- Inspect English/Russian labels and live input prompts. New physical D-pad navigation still requires manual acceptance.
- Normal renderer: `godot --path . --script dev_tools/test_playground_smoke.gd`; inspect ignored screenshots. F5 and staging remain the foundation scene; no playground resources are exported.

## M7

- Run dev_tools/validate.ps1: all M0–M6 regression checks plus M7 at 30/60/144 FPS.
- Verify per-player ordered/unordered rules, optional vs mandatory, invalid Finish without teleport, duplicate events, static spawn clearance, moving support rejection, blocked checkpoint/Start retries, persistent fatal overlap and 45-tick immunity.
- Run tests/checkpoint_respawn_test.gd with normal renderer and -- --render-smoke; inspect builds/m7-lifecycle.png.
- Manually play dev_tools/lifecycle_playground.tscn: barrier, cyan checkpoint feedback, red hazard jump, death scatter/ring, yellow Finish, held R/top-face reset, Escape to all twelve M6 stations.
- No tests may open real-user profile storage. Windows export/boot runs in CI; Linux/Steam Deck/hardware gamepad remain manual coverage.

## M8

- Full dev_tools/validate.ps1 includes platform_modules_test.gd at 30/60/144 FPS and compares M8 hashes.
- Test absolute routes/waits/reverse/loop/stop, invalid configs, one-way passage/landing,
  horizontal/vertical carry and jump-off, temporary activation/disappearance/occupied restore,
  permanent break, Dash-to-pad launch, lifecycle locks and unsafe respawn support.
- Check real interactions on all four M8 playground stations; M6 still checks every station's navigation/localization.
- Run platform_modules_test.gd with normal renderer and test_playground_smoke.gd for Russian HUD captures.
- Manually review feel, moving-platform seams/return journey, diagonal pad and gamepad navigation.
- Keep saves isolated; no platform fixture constructs SaveStore.

## M9

- Full `dev_tools/validate.ps1`: M0–M8 regression plus hazard_modules_test at 30/60/144 FPS.
- Exercise static/timed/local-sensor spikes, static/path saws, permanent/cyclic lasers and
  the existing DeathZone with actual collision bodies, warning phases and invulnerability.
- Verify inactive hazards reject unsafe respawn anchors; M7 falls back to clear static Start.
- Verify separate turret IDs/targets, two simultaneous barrels, LOS geometry, range loss,
  full warning, limited lead, minimum cooldown and target death/Finish cancellation.
- Fill five rounds per target and ten globally; override global and engagement caps;
  confirm skipped shots enter cooldown without deferred bursts. Destroy engaging turrets.
- Sweep fast projectiles through another player, toward the designated capsule and toward
  a 2px wall. Check immunity, reuse exceptions/IDs, lifetime expiry and target removal.
- Repeat pool fill/expiry 50 times and station teardown 12 times. Check stable object IDs,
  cleared signal connections and absence of ObjectDB/resource leak warnings on exit.
- Normal renderer: `tests/hazard_modules_test.gd` and `dev_tools/hazard_playground_smoke.gd`;
  inspect `builds/m9-station-16.png` through `-21.png` (ignored local artifacts).
- Manual review: stations 17–22, both channel colors, trigger sensor, warning timing,
  projectile readability, dropdown/PgUp/PgDn/D-pad, held R/top-face once per second hold.
- No test may initialize production SaveStore; staging remains the foundation scene.

## M10 Time Trial acceptance

- Run full validate.ps1: now M0–M10, parser including map/UI, hash manifest and isolated boot.
- Test hint expiry/early Ready, 3/2/1/GO, blocked movement, exact timer ticks at 30/60/144 FPS.
- Traverse both checkpoints and Finish; skipped/out-of-order triggers must refuse completion.
- Die, respawn and pause: clock continues through death and stops during pause; record stays valid.
- Hold restart below/at 0.5s during death/respawn; hold longer: only one restart until release.
- Verify Retry clears all phases/progress/deaths and skips hint; menu entry replays hint.
- Check first/improved/equal/worse PB, complete-run deltas, segment minima and disk reload.
- Check v2 migration, malformed record, read-only/write failure and identity mismatch.
- Force developer death/relocation: invalid status and no record write.
- Repeat course rebuild and menu reentry: stable nodes/signals and no pooled shots retained.
- Run dev_tools/time_trial_smoke.gd normally: isolated GUI + motor-driven finish, RU/EN and
  keyboard/gamepad prompt captures. Review physical controller focus/hotplug manually.

## M11 manual acceptance

- Open C:/Godot Projects/ProjectVelocity/project.godot and F5. New/v3 profiles choose
  language before nickname. Relaunch skips onboarding only after successful Continue.
- Profile: Latin/Cyrillic 3–15 characters; invalid input disables Save. Cancel language
  and name edits. Save/relaunch and verify nickname, language, UUID and old PB persist.
- Customization: adjust all six RGB channels by mouse, arrows and controller; Save,
  enter Solo and Retry. Verify the same colors; Cancel must restore saved appearance.
- Visit New Game, maps, Profile, Settings/Controls, Online placeholder and Level Editor
  in RU/EN using mouse, keyboard, D-pad/left stick and shoulders. Check initial focus,
  Tab/Shift-Tab, return focus, disabled entries, modal keyboard Done/Cancel and Quit Cancel.
- Try repeated Confirm/Back during fades and hold movement/jump while entering a map.
  Reconnect a physical controller, switch back to mouse/keyboard while editing a name.
- Play Training Circuit: hint/countdown/run/checkpoints/death/Finish/result/Retry/maps/menu.
  Pause must freeze time and stay eligible; 0.5 s restart must trigger once per release.
- Review window sizes 1280x720, 1920x1080 and 1280x800; text/focus must stay readable and
  scroll into view. Linux/Steam Deck and physical controller family checks remain manual.
- F6 dev_tools/test_playground.tscn: all 22 stations; F6 lifecycle_playground.tscn remains.

Automated M11 checks inject unique OS-cache save paths; never point tests at real saves.
