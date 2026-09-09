# M12 validation — Settings

Implementation: feature/m12-settings in C:/Godot Projects/ProjectVelocity.
Build 0.12.0-dev /14; schema 5; protocol 1. No gameplay-content manifest change.

## Automated evidence

- tests/settings_test.gd: isolated schema 4→5 migration, all required fields reject
  null/corrupt values, all render caps/presets, real AudioServer levels/mutes/zero,
  accessibility ranges/correction uniforms, reload, defaults, cancelled input edits,
  independent profiles/conflicts, foreign fields, onboarding and actual PB preservation.
- Injected DisplayAdapter: provisional data stays off disk; Keep, Revert, 15-second
  timeout, focus interruption, partial native failure, write failure and teardown rollback.
- tests/settings_runtime_test.gd: RU/EN pages, synthetic keyboard/controller navigation,
  UI scale 0.5/1/1.5/2 with text 1.5, bounded panel, visible focus/captions,
  HUD text/scale bounds and return to Solo.
- Final local dev_tools/validate.ps1 M0–M12 passed with exit 0. CI status is recorded in the PR.
  Its M0–M11 regressions include 60 Hz movement/camera/platform/hazard/trial replays,
  22 playground stations, parser/import, isolated boot and the M11 UI loop.

## Native renderer evidence

Command: C:/Godot/Godot.exe --path . --script tests/settings_runtime_test.gd
The test creates a UUID-named OS-cache save and mutes Master before playback.
Observed: Godot 4.7.2.stable.official.ed1daf0bf, OpenGL 3.3 Compatibility,
AMD Radeon (TM) Graphics; desktop 1920×1200.
Actual window readbacks: 1280×720, 1280×800, 1600×900, 1920×1080, 1920×1200,
1680×720 (ultrawide window), 960×1080 and 640×360. All retain the 1920×1080
competitive content area. Native fullscreen and borderless preview/readback, controller
Revert, keyboard Keep, mouse Revert and VSync on/off readback pass.
Marker: PROJECTVELOCITY_M12_RUNTIME_OK native=true, no engine warnings/errors.

RU/EN page captures, scale extrema and confirmation captures are generated under builds/
and visually inspected; artifacts remain ignored. Extreme-scale RU heading wrapping was
fixed after capture revealed overflow. Deferred focus reveal keeps a setting and its
caption visible after final layout. Native testing also exposed unsupported GLES3
2D MSAA; presets use supported filtering and procedural effects instead. The input
validator retains legacy StringName action keys, verified by the existing M2 suite.

This does not certify a physical ultrawide monitor, Steam Deck performance, Linux/Wayland,
USB/Bluetooth hotplug or physical controller drivers. Controller tests inject Godot events;
there were zero connected physical controllers. Local export templates were unavailable;
Windows export/boot is checked by CI using checksum-verified official templates.

## Manual review in the main folder

1. Open C:/Godot Projects/ProjectVelocity/project.godot and press F5. Confirm build /14.
2. Settings → each of Video/Audio/Controls/Accessibility: change values; Cancel, then
   repeat and Apply. Exit/restart F5 and verify the saved values and unchanged profile/PB.
3. Video: try window size and each window mode. Exercise Keep, Revert, 15-second timeout,
   Alt-Tab, and closing during preview. Restart into the last confirmed mode.
4. Controls: select keyboard then gamepad; rebind movement/Jump/Dash/Restart, try a conflict,
   cancel capture, reset one profile; adjust deadzones/family. Verify the other profile survives.
5. Test 50–200% UI and 75–150% text; reach bottom actions with scroll/Tab/shoulders.
   Check HUD opacity, contrast/color correction, flash, speed effect and shake in Solo.
6. Listen at a comfortable level: Master/SFX/UI mute and zero must silence placeholders.
   Music/Ambience remain empty slots. Check Solo hint/countdown/run/pause/Retry/results
   and fresh movement/Dash triggers on UI exit. Quick Restart remains 0.5s once per release.
7. Review the PR and CI; merge only with explicit user approval. Do not start M13 here.
