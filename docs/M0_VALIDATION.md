# M0 validation evidence

Date: 2026-09-06. Host: Windows x64. Implementation commit: cd8ece5.

## Acceptance passed

- Godot 4.7.2.stable.official.ed1daf0bf.
- Graphical Godot editor opened with Compatibility/OpenGL and exited zero, with no errors or warnings in captured output.
- Editor import and individual parser checks for all six bootstrap/test/tool GDScripts passed.
- Bootstrap integration assertions passed: engine version, 60 Hz, renderer/aspect, version consistency, config, build flags, logging format, English/Russian translation availability and DEV watermark.
- Actual main scene headless startup crossed a physics tick, printed PROJECTVELOCITY_BOOT_OK and exited zero.
- Clean staged-file snapshot without .godot cache passed import, parsing, tests and startup.
- Real OpenGL Compatibility runtime on AMD Radeon Graphics passed. The captured 1280x720 English placeholder was visually reviewed: centered readable text and DEV label.
- Staged Git whitespace check passed; working tree clean after implementation commit.
- [First push CI run](https://github.com/grislytoe/ProjectVelocity/actions/runs/34044968351): success.
- [First PR CI run](https://github.com/grislytoe/ProjectVelocity/actions/runs/34045006456): success.
- CI verified official engine/template SHA-512 checksums, ran validation, exported Windows x64 debug staging, smoke-booted the executable and uploaded build/log artifacts.
- Exported executable log independently downloaded and inspected: Godot 4.7.2, STAGING label, PROJECTVELOCITY_BOOT_OK, no stderr.
- [Windows staging artifact](https://github.com/grislytoe/ProjectVelocity/actions/runs/34044968351/artifacts/9992828599): 35,362,221-byte archive. GitHub authentication required; artifact retention applies.
- [Review PR #1](https://github.com/grislytoe/ProjectVelocity/pull/1): feature/m0-bootstrap into dev. Developer performs final merge.

## Environment limitations and remaining review

The local full export-template download was stopped because transfer speed was impractical. Windows export was validated on the GitHub Windows runner instead. No local template installation or release build was performed.

The Codex sandbox process helper and image viewer failed with helper_unknown_error; explicitly approved host execution was used. This is an environment issue, not a Godot startup failure. No claim of sandbox recovery is made.

Target hardware performance, Linux export and Steam Deck behavior remain untested. M0 adds no gameplay, networking, saves or production service integration. Developer must configure/protect the stable main branch and review/merge the PR; nothing was pushed or merged to main.
