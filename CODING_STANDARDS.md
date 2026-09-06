# Coding standards

- Godot 4.7.2 Stable; typed GDScript for parameters, returns, members and collections wherever practical.
- Tabs in GDScript; UTF-8, LF, final newline, no trailing whitespace. Keep lines near 100 characters.
- snake_case files, folders, functions and variables; PascalCase class/node names; UPPER_SNAKE_CASE constants. Private members start with an underscore.
- Prefer one focused responsibility per script, composition, explicit ownership, Resources for tuning, and signals for notifications.
- Use separate explicit gameplay and animation state machines when implemented. Avoid giant conditional controllers.
- Keep tuning outside state code. Explain intent in comments; document public contracts with doc comments.
- Cache node references. Avoid per-frame SceneTree searches and unnecessary physics-frame allocation.
- Keep pure simulation testable and deterministic; use fixed physics ticks. Keep presentation independent.
- No Steam SDK calls in gameplay, network transport calls in movement, or secrets in code/logs.
- Use AppLogger with a category. Debug output is development-only. Warnings/errors remain visible. Never log credentials or automatically upload logs.
- Add behavior-focused tests for new logic. Run the validation script and inspect logs before committing.
- Track Godot-generated .gd.uid files; ignore the .godot cache and local export credentials.

## Git convention

`main` is developer-reviewed stable history. `dev` is integration. Work on `feature/<milestone>-<topic>` from dev once it exists. Use focused imperative commits and PRs to dev; developer approves promotion to main. Never push directly to main or merge main automatically.

The repository began with an unborn main branch. A small initial conventions/specification commit establishes dev; the M0 implementation follows on feature/m0-bootstrap for review into dev. No main commit is fabricated. Initial GitHub default-branch setup and branch protection require developer administration.

Before committing, inspect staged changes and run validation. Never commit credentials, generated cache, tool downloads, logs, or exports. Additional dependencies need the review information in DEPENDENCIES.md.
