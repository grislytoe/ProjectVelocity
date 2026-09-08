# Milestone workflow

- Each milestone runs in a separate Codex task, always in the main folder
  `C:/Godot Projects/ProjectVelocity`. Never create a worktree or another project copy.
- Start a `feature/<milestone>-<topic>` branch from the approved, synchronized `dev`
  in that same folder. Preserve unrelated local user changes and exclude them from commits.
- Read repository instructions and `docs/MASTER_SPECIFICATION.txt`; implement and validate
  only the assigned milestone. Include this agreement in the next milestone handoff.
- Update documentation and build identity, run the full validator, commit, push and open
  a PR into `dev`. Check remote branch, PR and CI. The user manually reviews the module
  and explicitly authorizes merge. Never merge automatically or start the next milestone.
