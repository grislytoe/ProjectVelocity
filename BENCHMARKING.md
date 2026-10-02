# Performance benchmarking

M24 provides a development-only, reproducible renderer/gameplay benchmark. It is excluded by
the existing `dev_tools/*` staging export filter and never reads production saves. Raw runs live
under ignored `builds/validation/m24-<scenario>-<preset>-<uuid>`; commit only concise sanitized
tables such as `docs/M24_VALIDATION.md`.

## Required setup and fingerprint

Use official Godot **4.7.2.stable.official.ed1daf0bf**, the Compatibility renderer and the
branch/commit being evaluated. Record CPU model/core count, GPU model and driver, installed RAM,
OS/build, rendering API, resolution, preset, power profile, window mode, VSync/FPS cap and exact
Git SHA. Do not record machine/user names, absolute personal paths or hardware identifiers.

The launcher records engine/game/build/SHA, renderer/driver, sanitized CPU/GPU/OS/RAM and the
active power-profile label. It uses a unique ignored output folder, owns one exact process handle,
enforces an explicit timeout and samples process working set/private bytes externally. Missing or
invalid values fail the GDScript schema; unavailable GPU/platform counters are objects with an
explicit reason, never fabricated zeroes.

```powershell
./dev_tools/performance_benchmark.ps1 -Godot C:/Godot/Godot.exe `
  -Scenario hazard_station -Preset low -Resolution 1920x1080
./dev_tools/performance_benchmark.ps1 -Godot C:/Godot/Godot.exe `
  -Scenario solo_traversal -Preset balanced -Resolution 1280x800 -Samples 4200
./dev_tools/performance_benchmark.ps1 -Godot C:/Godot/Godot.exe `
  -Scenario load_leak -Preset balanced -Resolution 1280x800 -Unpaced
```

For throughput/hotspot work add `-Unpaced`; the launcher disables both VSync and the FPS cap but
never changes 60 Hz physics. Paced final smoke uses the selected user-style VSync/60 FPS state.
The 1280×800 profiles retain the 1280×720 world buffer inside the fixed competitive frame.

## Scenarios

- `solo_traversal`: complete real 41,600 px Foundry, M14 deterministic input recipe, actual
  controller/collision/checkpoints/Finish/camera/background, local player plus 30% opponent
  presentation. A complete run reports `route_complete=1`.
- `hazard_station`: full Foundry plus two presented players, three real dual-channel turrets
  (the approved three engagements per target), 5 projectiles per target / 10 global, an explicit
  over-cap shot, cyclic hazards/platforms, procedural VFX and stable pool instance IDs.
- `ui_first_open`: real menu, unavailable production lobby and final-results overlay first-open
  paths. RU/EN/focus semantics remain covered by the existing UI suites.
- `load_leak`: one cold-ish load followed by ten measured load/run/teardown cycles. The first
  cycle establishes engine caches and is excluded from growth deltas.
- two-process network: use `test_local_network.ps1 -Rendered -Race -Map industrial` with M17
  profiles. Each endpoint's `stress.json` now includes active-gameplay-only frame/process/physics,
  draw/primitives, memory/object counts and construction time. Renderer timings are sampled only
  in `-Rendered` runs; headless functional gates report them as unavailable. Reconnect
  pause/results are excluded.

CI runs deterministic statistics/schema/cap tests and one bounded normal-renderer composition
smoke. CI does not apply machine performance thresholds and cannot certify target hardware.

## Sampling and interpretation

Warm-up is explicit (normally 120 frames; CI smoke 30). Paced measurements use at least 300
gameplay frames; the full route uses 4200. Repeat key profiles at least three times and compare
the same engine/SHA/scenario/seed/settings. Keep every unexplained outlier. Loading, the explicit
45-second reconnect pause and result screens are separate phases, not gameplay frame regressions.

Percentiles use nearest-rank `ceil(p*N)`. `1% low FPS` is `1000 / p99 frame ms`; it is not an
average of a slowest-frame subset. M24's engineering convention is paced p95 ≤17.5 ms (half-tick
Windows scheduler tolerance), p99 ≤25 ms and zero gameplay frames >33.333 ms after warm-up. This
is an M24 convention, not wording from the master specification. Counts above 16.667/25/33.333 ms
are always retained.

The master target can be marked PASS only on the specified physical low-end class or physical
Steam Deck/comparably proven SteamOS hardware. A fast/other Windows GPU may prove profile
composition and local headroom only; its certification status must remain BLOCKED.

## Result schema 1

Every JSON contains `scenario`, identity/environment/configuration, warm-up/sample/seed,
frame/process/physics distributions, draw/primitives, objects/resources/orphans, Godot static and
peak memory, external working set/private bytes, decoded texture budget, pool/leak/first-use data
and `PASS|BLOCKED|FAIL` with reason. A matching text summary and CSV row are written beside it.
`tests/performance_benchmark_test.gd` fixes percentile, schema and classification behavior.

Cold shader/driver compilation is reported rather than hidden: Godot can preload resources and
warm bounded pools, but this project cannot guarantee driver shader cache state across updates.
