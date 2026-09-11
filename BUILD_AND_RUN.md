# Build and run

## Requirements

Godot 4.7.2 Stable (standard GDScript edition), Git, and PowerShell. No external GDScript test framework or runtime SDK is needed. Windows staging export additionally needs the matching official 4.7.2 export templates.

## Local commands

From the repository root:

~~~powershell
godot --version
godot --editor --path .
powershell -ExecutionPolicy Bypass -File dev_tools/validate.ps1
powershell -ExecutionPolicy Bypass -File dev_tools/validate.ps1 -ExportWindows
~~~

If Godot's GUI launcher does not wait in your shell, pass the installed console executable using `-Godot C:/Godot/Godot.exe` (or its actual console wrapper path). The validator starts and waits for the selected process, applies a 120-second timeout per check, and rejects engine errors/warnings as well as missing success markers.

The validator imports assets, parses all bootstrap/test scripts, runs M0 bootstrap, M1 persistence and M2 input behavior tests, boots the actual main scene through a physics tick and checks Git whitespace. With -ExportWindows it exports and boots the Windows staging executable. Logs go to ignored builds/validation.

## Build identity

Version 0.15.0-dev and build number 21 live in core/build/build_info.gd. Keep project.godot's application version synchronized; tests enforce this. OS.is_debug_build() is the authoritative development flag. The staging export adds the staging feature; its label is STAGING. Release-mode engine binaries disable development debug logging; release exports require developer review and are not part of M0.

## CI

GitHub Actions runs on feature/* and dev pushes, PRs into main/dev, and manual dispatch. It downloads the exact engine/templates from the official release, verifies SHA-512 against the release manifest, runs the same validator on Windows, exports debug staging, smoke-boots the executable and uploads build/log artifacts. Actions are pinned to commit SHAs.

## Logs

Godot stores local rotating logs at user://logs/project_velocity.log (up to five files). On Windows the default project user directory is %APPDATA%/Godot/app_userdata/ProjectVelocity. CLI validation also captures stdout/stderr under builds/validation. No logs are uploaded by the application.

For a local GPU screenshot smoke test: godot --path . --script dev_tools/presentation_smoke.gd --language en. Run validation first to create the output directory. The screenshot is saved to builds/validation/placeholder.png.

Normal startup loads/creates user://saves/save.json. Use --smoke-test for automated startup: it creates and removes an isolated OS-cache save directory. Tests and render capture also inject isolated stores. No save/profile data is committed.

M2 startup creates InputLayer and InputPreferences. Synthetic tests need no physical gamepad. See CONTROLS.md for mapping APIs and the remaining hardware validation checklist.

M6 manual fixture: `godot --path . dev_tools/test_playground.tscn` (or open it and use editor F6). See TEST_PLAYGROUND.md for station controls. Normal-renderer capture script: `godot --path . --script dev_tools/test_playground_smoke.gd`. The standard validator includes M6 station integration; export still excludes all dev_tools/tests.

M7 manual review: run dev_tools/lifecycle_playground.tscn (F6), or use the M7 button in the M6 playground. Build identity: 0.7.0-dev / build 8. Normal-renderer smoke: godot --path . --script tests/checkpoint_respawn_test.gd -- --render-smoke (isolated; no saves).

M8 is integrated into dev_tools/test_playground.tscn, stations 13–16. Build 0.8.0-dev / 9.
The full validator now covers M0–M8. Normal-renderer platform check: godot --path . --fixed-fps 60 --script tests/platform_modules_test.gd.
On Windows use Start-Process with -PassThru, -WindowStyle Hidden, redirected logs and WaitForExit as in validate.ps1.
See WORKFLOW.md: all milestones use this main project folder, separate tasks and feature branches.

M10 manual entry: C:/Godot Projects/ProjectVelocity/core/bootstrap/main.tscn (F5).
Choose New Game → Solo → Training Circuit → Ready; pass both cyan checkpoint gates, then the lime
Finish gate. Result Retry and held R restart to countdown; Escape pauses. Menu → Settings → Controls
provides active-device rebinding. Course content is gameplay/race/solo_course.tscn.

## Current entry point

Current build: **0.15.0-dev / build 21**, save schema **5**, protocol **2**.
From C:/Godot Projects/ProjectVelocity open project.godot with Godot 4.7.2 and press F5.
Complete language/nickname onboarding, then New Game → Solo → Map Select → Foundry Run or Training Circuit.
Profile header, Customization, Settings → Controls and Level Editor are available.
Run the full M0–M15 validator with `./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe`.
Normal-renderer UI tests: `Godot --path . --script tests/ui_foundation_test.gd -- --render-capture`.
These use isolated temporary saves. Do not delete or modify real saves to run tests.
On this machine the console wrapper lacks its expected sibling executable; use Godot.exe
with Start-Process/WaitForExit as validate.ps1 does. CI installs matching official files.

M13 uses the shared MapDefinition catalog, structural validation and PV-MAP-1 checksum.
Training Circuit now publishes map version 3 and preserves older PBs separately; save schema remains 5.
F6: res://dev_tools/map_framework.tscn. See docs/MAP_AUTHORING.md and docs/M13_VALIDATION.md.

## M14

M14 route/evidence and human review: docs/M14_INDUSTRIAL_TRACK.md. Both official maps are checksum-verified in isolated editor/export boot. Local export templates remain optional; CI installs the pinned official templates.

## M15 Local Network

See NETWORKING.md for two-process launch and emulator commands. The localhost launcher
requires PowerShell 7.4+ for per-process environment isolation. Windows staging also boots
the developer network scene in CI. There is no EOS/Steam requirement.
