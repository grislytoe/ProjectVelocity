# Next steps

Review the M20 Online Lobby UI PR from `feature/m20-online-lobby-ui` into `dev`.
See [M20 validation](docs/M20_VALIDATION.md) for the UI/service contract and evidence.
M20 UI/contract acceptance is independent of live EOS end-to-end acceptance, which remains
BLOCKED by the [M19 prerequisites and native execution boundary](docs/M19_BLOCKERS.md).

After prerequisites and explicit native integration review, a future executor must bridge
OnlineService/LobbyService to LobbyClient, publish settings and Ready atomically, enforce
private membership/capacity and hand accepted Start to M16's loading/hints/round authority.
Prove that through two authorized standalone Internet clients; never substitute the UI fake.

Merge only after explicit user authorization. Do not start M21 in this task.
Each milestone uses a separate Codex task in `C:/Godot Projects/ProjectVelocity`, no worktrees
or project copies. Read WORKFLOW.md and the master specification, branch from synchronized
approved dev, preserve unrelated user changes, and carry this agreement into the handoff.
