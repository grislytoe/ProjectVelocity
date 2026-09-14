# Testing checklist

## M15

- Full `dev_tools/validate.ps1`: M0–M14 plus network core at render30/60/144,
  separate-process clean sessions at those caps, wan/30Hz reconnect, Industrial stress,
  and collision lifecycle events. Physics remains60. MTU framing has adversarial tests.
- Run `dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Rendered`. Inspect both
  endpoint screenshots/HUD and move both windows manually: alpha30%, no remote selector,
  local camera, fresh Dash, no mutual collision. CI exports/boots Windows Staging.
- Verify F8 guest → host pause; F9 guest → authenticated Ready/respawn/resume. Host close
  → guest ended. Two-process tests isolate data/logs, enforce hard timeouts and exact-handle
  cleanup; in-tree actors do not substitute for them. See docs/M15_VALIDATION.md.
- Simulated stress is not physical WAN/Linux/Steam Deck certification; see NETWORKING.md.


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
# M12 settings acceptance

- Run dev_tools/validate.ps1 with Godot 4.7.2: all M0–M12 checks, parser/import,
  isolated boot and unchanged gameplay/camera replay hashes must pass.
- Run tests/settings_runtime_test.gd without --headless for real DisplayServer,
  VSync/readback, RU/EN screenshots, extreme scales, modal input and Solo return.
  Its cache save and muted fixture are isolated; screenshots/logs stay under builds.
- In F5, test each category: change values, Apply, restart, confirm reload; edit again
  and Cancel; restore Defaults and verify they do not persist until Apply/Keep.
- Test keyboard and a physical pad: rebind movement/Jump/Dash/Restart, reject a conflict,
  cancel capture, reset one profile, adjust deadzones and prompt families; check fresh
  input on Solo entry, Dash aim, 0.5s restart and pause record eligibility.
- Preview each native mode: Keep, Revert, wait 15 seconds, Alt-Tab and close application.
  Restart must use the last confirmed mode. Try 1280×720, 1280×800 and desktop size.
- Check UI scale 50/100/150/200% with text 75/100/150%; reach Apply/Cancel through
  scrolling and controller focus. Verify bars on ultrawide/16:10 and unchanged camera view.
- Verify five audio bus levels/mutes (including zero), UI clicks and player SFX. Music
  and ambience are intentionally empty; do not mistake missing final content for routing.
- Verify contrast/color correction, flash controls, speed trails, shake Off/Low/Medium/High
  and HUD 50–100%; inspect legibility without changing gameplay timing.

## M13 map framework

- Run full dev_tools/validate.ps1 with Godot 4.7.2, including map_framework_test.gd.
- F5 → New Game → Solo → Map Select: compact name/personal-best rows with preview on the right; five rows and Back fit at default UI scale; Hint/Countdown/Run/
  Results, PB/splits, ordinary death clock continuation, pause, retry and 0.5s Quick Restart.
- F6 dev_tools/map_framework.tscn: 1 valid multi; 2 valid single; 3 seam gap; 4 missing
  anchor; 5 checksum mismatch. Rejected maps show diagnostics with no active geometry.
- Inspect aligned floor joins, entrance/exit rings, grid and safe respawn dots.
- Verify repeated map exit/retry/failure leaves no actors, pool shots or stale callbacks.
- Validate identity across editor/compiled Windows staging export; run --smoke-test only
  with its isolated save injection. Do not run tests against production user saves.
- M12 native test: tests/settings_runtime_test.gd without --headless; check selected
  fullscreen/borderless world buffer, sharp UI, 16:9 framing, minimum 1280×800 and rollback.
- Level Editor still displays In Development. All 22 playground stations remain present.

## M14

M14: full validate.ps1 includes Industrial structural/fallback/PB/UI fixtures and input-driven main (30/60/144), express and eight-death recovery runs. Human clean completion, Normal feel, optional express entry, camera/telegraphs and hardware review remain open. Follow the exact checklist in docs/M14_INDUSTRIAL_TRACK.md before authorizing merge.
## M16 review additions

- Run full `dev_tools/validate.ps1`: M0–M15 retained plus M16 real world/packet/round tests
  at render30/60/144 and actual separate host/client clean, stress malicious and wan reconnect.
- Review [docs/M16_VALIDATION.md](docs/M16_VALIDATION.md) commands and declared coverage.
- Verify early Finish feedback, per-player checkpoints, safe respawn/immunity, ready
  withdrawal, both Finish/results, winner spectating and guest F6/host F7 round retry.
- Confirm host rejection metrics while honest play continues; projectile caps/generations,
  pool retirement and unique event presentation; no Solo records from network mode.
- Inspect rendered HUD and local/remote presentation; manually review two-window play.
- CI must pass official-template Windows export, ordinary/network boot and exported
  separate-process scenario. Merge remains a separate user decision; no M17.

## M17 network stress

- [ ] Run full dev_tools/validate.ps1 (M0–M17, replay/map hashes, parsers, mandatory ENet gates).
- [ ] Run dev_tools/test_network_stress.ps1 -Extended -Rendered; inspect both endpoint stress.json,
  evaluation.json and images for clean/80/150/200/250ms, including1280x800 and1920x1080.
- [ ] Confirm simulated one-way/RTT versus measured RTT labels, F2 next/F3 apply/F4 clean/F5 window.
- [ ] Check RU/EN warning above200ms and hysteresis; it must not block movement or race progress.
- [ ] Verify host/guest independent controls, full Industrial collision/event/Finish fixture,
  forged claims rejected, winner/progress/event counts and clock convergence, cleanup zero.
- [ ] Running and Results guest reconnect, host drop, repeated profile/session cleanup;
  same seed/input trace equality is distinct from OS-dependent whole-process packet counts.
- [ ] Review ordinary/moving error percentiles separately from lifecycle/injection counters.
- [ ] Check measured motion traces; images are presentation evidence only.
- [ ] PowerShell5.1 launcher run, exact PID cleanup and no real saves/logs/images committed.
- [ ] User manual two-window review and explicit merge authorization; never auto-merge/start M18.

## M18 critical gate addition

- Retain the complete `dev_tools/validate.ps1` M0–M17 regression and exported ENet gates.
- Run checksum/path inspection before native evaluation and retain only sanitized evidence.
- Native load/global init/shutdown/invalid config must be reported separately from services.
- Full plugin import/export, configured platform tick, scene teardown, Auth/Connect,
  two-identity Lobby/P2P, negative online cases and SteamOS remain blocking until executed.
- Review SDK1.19.1.2 notices and commercial/free redistribution package before distribution.
- See [M18 matrix and commands](docs/M18_COMPATIBILITY.md); stop for developer review,
  with no automatic merge or production integration.
