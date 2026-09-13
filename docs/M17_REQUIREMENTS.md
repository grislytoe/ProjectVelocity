# M17 — Network Stress Tools: requirements and model

Workspace and base: main checkout only, `feature/m17-network-stress-tools` from approved
`dev` 2d11206f43534a84025d3e476b44328f6be7a6d0. Base Actions run34684846563 succeeded.
No worktree. Preserve project.godot SHA256
5B9713ACA5045DD697EA09DF21E9DE658283B782B3B0C8F2CC540539FABB65AC byte-for-byte.

Master sections26–29,32–34 prescribe host authority, prediction, reconciliation,
interpolation, physics60, snapshots20–30, synchronized race lifecycle, guest reconnect45s,
host-drop termination and latency/loss/jitter/disconnect emulation. Section28 states
0–80ms near ideal,80–150ms comfortable,150–200ms playable and “200 ms: display connection
warning.” It does NOT specify RTT versus one-way, numeric error/comfort tolerances,
loss/jitter rates, burst loss, bandwidth limits, or a telemetry sampling algorithm.

M17 convention (explicit implementation choice): quality labels refer to measured RTT;
shared boundaries belong to the lower band. The current user request clarifies warning
strictly ABOVE200ms. Enter after30 fixed service ticks above200; clear after60 fixed ticks
at/below180. Only fresh accepted PONG estimates (age<=120ticks), while joined, qualify.
A stale/disconnected estimate does not dismiss an existing warning. Reconnect status is
separately visible. This presentation policy cannot affect physics or race validity.

All built-in delays mean EXTRA application-message delay, applied once INBOUND at each
endpoint, above real ENet reassembly. Symmetric simulated RTT=2×configured one-way.
Actual monotonic PING/PONG RTT includes ENet delivery, polling and OS scheduling. Do not subtract
baseline or claim a simulated80ms profile measures exactly80ms. One-way RTT/2 is an
estimate assuming symmetry, not an independently measured one-way latency.

Implementation extends NetworkEmulator, PredictionHistory, SnapshotBuffer and the existing
local_network composition/real-process fixture. No second emulator, dependency, wire/schema
change, production diagnostics, network service, user settings write or Solo record access.
Runtime identity0.17.0-dev/23, protocol3/wire2, save5; map/checksum and shared gameplay code
remain unchanged. project.godot editor metadata remains0.15.0-dev by preservation agreement.

Coverage mapping:
- NetworkConditionProfile: finite/range/type validation, immutable applied copy, built-in
  exact-ms profiles and strict<=4KiB JSON overrides; unknown fields/profiles rejected.
- NetworkEmulator: seeded uniform/triangular jitter, independent inbound/outbound loss,
  inbound duplication/reorder, deterministic fractional tick scheduling, bounded queue,
  expiry, disconnect closure and reopen; existing ENet/session retry contract.
- NetworkTelemetry/PredictionHistory/SnapshotBuffer: bounded percentiles, lifecycle and
  divergence exclusions, ordinary/moving errors, correction/replay/history/ack metrics,
  snapshot age/gaps, interpolation states, RTT, disconnect duration, traces, warning.
- Local HUD: F2/F3/F4 profile selection/apply/reset, F5 metric window, F8/F9 disconnect/retry;
  explicit measured/simulated units, RU/EN warning, no production access.
- JSON/evaluator: identities, per-direction/type message counters, cleanup and functional
  invariants; exact quality labels and no invented numerical comfort certification.
- Existing two-process launcher: real Industrial fixture, authority attacks, comparison,
  timeouts and owned cleanup. Full legacy gates retained, mandatory M17 representative
  profiles, optional extended render/boundary/repeat/disconnect/profile-change matrix.

Not claimed: physical WAN quality, client authority, historical-world rollback, subjective
comfort certification, production lobby/results, burst/network-layer datagram/bandwidth
shaping. These are outside the prescribed toolkit and numerical master targets.
