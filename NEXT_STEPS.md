# Next steps

Review the M24 PR from `feature/m24-performance-benchmark` into `dev`; do not merge without explicit
authorization and do not start M25 in this task. Reproduce the blocked matrix in
`docs/M24_VALIDATION.md` on the approved low-end Windows class and physical Steam Deck, preserving
physics/network rates and attaching sanitized schema-1 results/profiler captures. Investigate the
two-render-process iGPU stutter and remaining cold construction only when the target trace proves
the same hotspot. M19 live EOS/Internet remains a separate BLOCKED gate.

Historical M23 handoff follows.

Review the M23 Art Pass PR from `feature/m23-art-pass` into `dev`. Use
`docs/M23_VALIDATION.md` for the exact generated-asset provenance, map identities, captures,
budgets and regression evidence. Merge only after explicit user authorization. Do not start
M24 in this task.

M24 may perform the dedicated target-hardware performance/optimization milestone after review;
it must not lower physics/network rates to hide presentation cost. Final character sheets and
additional environment assets should follow `docs/ASSET_SPECIFICATION.md` and the rejection
workflow in `docs/ASSET_GENERATION_PROMPTS.md`.

The M19 live EOS/Internet blocker remains unchanged: production Auth/Connect/Lobby/P2P,
authorized identities, native exports and real Internet evidence are still absent. Local ENet
and M22 reconnect tests do not satisfy it.

Historical handoff below describes the completed M22 boundary.

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
