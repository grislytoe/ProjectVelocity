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

Version 0.2.0-dev and build number 3 live in core/build/build_info.gd. Keep project.godot's application version synchronized; tests enforce this. OS.is_debug_build() is the authoritative development flag. The staging export adds the staging feature; its label is STAGING. Release-mode engine binaries disable development debug logging; release exports require developer review and are not part of M0.

## CI

GitHub Actions runs on feature/* and dev pushes, PRs into main/dev, and manual dispatch. It downloads the exact engine/templates from the official release, verifies SHA-512 against the release manifest, runs the same validator on Windows, exports debug staging, smoke-boots the executable and uploads build/log artifacts. Actions are pinned to commit SHAs.

## Logs

Godot stores local rotating logs at user://logs/project_velocity.log (up to five files). On Windows the default project user directory is %APPDATA%/Godot/app_userdata/ProjectVelocity. CLI validation also captures stdout/stderr under builds/validation. No logs are uploaded by the application.

For a local GPU screenshot smoke test: godot --path . --script dev_tools/presentation_smoke.gd --language en. Run validation first to create the output directory. The screenshot is saved to builds/validation/placeholder.png.

Normal startup loads/creates user://saves/save.json. Use --smoke-test for automated startup: it creates and removes an isolated OS-cache save directory. Tests and render capture also inject isolated stores. No save/profile data is committed.

M2 startup creates InputLayer and InputPreferences. Synthetic tests need no physical gamepad. See CONTROLS.md for mapping APIs and the remaining hardware validation checklist.
