# Next steps

Review the M21 Online Match / Series PR from `feature/m21-online-match-series` into `dev`.
See [M21 validation](docs/M21_VALIDATION.md) for local two-client evidence, exact versions and
the acceptance split. M21 transport-independent/local acceptance is independent of live EOS
end-to-end acceptance, which remains BLOCKED by the
[M19 prerequisites and native execution boundary](docs/M19_BLOCKERS.md).

After prerequisites and explicit native integration review, a future executor must bridge
OnlineService/LobbyService to LobbyClient, publish settings and Ready atomically, enforce
private membership/capacity and hand accepted Start to M21's generation-bound lifecycle.
Prove that through two authorized standalone Internet clients; never substitute the UI fake.

Merge only after explicit user authorization. Do not start M22 in this task.
Each milestone uses a separate Codex task in `C:/Godot Projects/ProjectVelocity`, no worktrees
or project copies. Read WORKFLOW.md and the master specification, branch from synchronized
approved dev, preserve unrelated user changes, and carry this agreement into the handoff.
