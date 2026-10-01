# Next steps

Review the M22 Disconnect / Reconnect PR from `feature/m22-disconnect-reconnect` into `dev`.
See [M22 validation](docs/M22_VALIDATION.md) for the exact deadline/order, phase matrix,
standalone local ENet evidence and acceptance split. M22 transport-independent/local acceptance
is independent of live EOS
end-to-end acceptance, which remains BLOCKED by the
[M19 prerequisites and native execution boundary](docs/M19_BLOCKERS.md).

After prerequisites and explicit native integration review, a future executor must bridge
OnlineService/LobbyService to LobbyClient, publish settings and Ready atomically, enforce
private membership/capacity and hand accepted Start to M21's generation-bound lifecycle.
Prove that through two authorized standalone Internet clients; never substitute the UI fake.

Merge only after explicit user authorization. Do not start M23 in this task.
Each milestone uses a separate Codex task in `C:/Godot Projects/ProjectVelocity`, no worktrees
or project copies. Read WORKFLOW.md and the master specification, branch from synchronized
approved dev, preserve unrelated user changes, and carry this agreement into the handoff.
