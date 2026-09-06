# M0 validation evidence

Date: 2026-09-06. Host: Windows x64.

## Passed locally

- Godot 4.7.2.stable.official.ed1daf0bf.
- Editor import and standalone parser checks for every bootstrap/test/tool script.
- Bootstrap integration assertions and main scene headless startup through a physics tick.
- Real OpenGL Compatibility startup on AMD Radeon Graphics, exit 0.
- Captured 1280x720 placeholder visually reviewed: readable centered English text and DEV label.
- GitHub authenticated repository access confirmed; origin is grislytoe/ProjectVelocity (private).

- Clean staged-file snapshot without .godot cache: imports, parser checks, integration tests and headless boot passed.
- Staged Git whitespace check passed.

## Acceptance still pending

- Windows staging export and exported executable startup.
- First GitHub Actions run and staging artifact.

The local full export-template download was stopped because transfer speed was impractical. CI will download the pinned, checksum-verified official templates. No release build is produced.

Sandbox process startup and the image viewer failed with helper_unknown_error; explicit host execution approvals were used. Headless and render checks passed outside that sandbox. No claim of sandbox recovery or low-end/Steam Deck performance is made.
