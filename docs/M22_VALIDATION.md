# M22 Disconnect / Reconnect — validation and acceptance split

Workspace `C:/Godot Projects/ProjectVelocity`; branch
`feature/m22-disconnect-reconnect`; base `origin/dev`
`8c863399cdd13888a43153d712bd308fa9014ed0`. Main folder only, no worktree.
Runtime **0.22.0-dev / build28**, protocol **5 / wire4**, save schema **5**.
The incompatible bump covers generation/identity-bound HELLO, reconnect WELCOME,
`RECONNECT_READY` and expanded durable reconnect baseline. Map content and save schema did not
change. User `project.godot` remains byte-identical SHA-256
`5B9713ACA5045DD697EA09DF21E9DE658283B782B3B0C8F2CC540539FABB65AC` and is excluded.

## Acceptance split

- **M22 transport-independent state machine + two-process localhost ENet: PASS** on the
  deterministic and process evidence below. LocalENetTransport is a development adapter.
- **Live EOS/Internet reconnect: BLOCKED.** M19 still lacks configured production
  Auth/Connect/Lobby/P2P, authorized identities, native exports and an Internet session.
  No localhost process, emulator profile or screenshot satisfies that gate.

## State/timing/order contract

M22 extends the single M21 `OnlineSeries`/`NetworkSession` lifecycle. Typed reconnect states are
`IDLE`, `PAUSED`, `AUTHENTICATING`, `BASELINE_SENT`, `RESUMING`, `EXPIRED`, `TERMINATED`.
On loss at service tick `D`, the host publishes deadline `D + 2700`. The deadline tick is
inclusive; the first expired tick is `D + 2701`. Packet admission occurs before expiry. Only
the fixed 60 Hz service clock advances during pause; all gameplay/world/race timers are frozen.

Host fixed order: packet decode/direction/scope → transport loss → reconnect handshake/expiry →
if unpaused, world and M7 Finish callbacks → 30-second Finish-window resolution → snapshot.
Reconnect on the deadline therefore succeeds; the next tick rejects it. Finish accepted before
loss stays immutable. Loss seen before world simulation freezes that tick. Exact-once result
recording prevents disconnect/Finish/expiry races from adding score twice.

Authentication requires the same session/map/checksum/build/protocol, memory-only guest
identity, rotating memory-only bearer and series/round/reconnect generation. Full baseline and
its host tick must be acknowledged before resume. A validated duplicate of the frozen baseline
retries the same generation-bound acknowledgement without reapplying world state, so shaped
loss of the first control packet cannot strand the handshake. Credentials/PUID/secrets are not
logged.

| Original phase | Successful recovery | Expiry |
| --- | --- | --- |
| Synchronized loading | restore loading acknowledgements | host wins current round once |
| Controls hint | restore frozen hint tick | host wins current round once |
| Countdown | restore frozen shared start tick | host wins current round once |
| Racing | safe checkpoint/Start recovery, same race clock | host wins current round once |
| 30-second Finish window | retain winner/deadline and remaining ticks | host wins once if result mutable |
| Round Results | restore immutable result, never gameplay | no extra award |
| Between-round Ready | restore Ready/result state | no extra award |
| Final Series Results | restore immutable final history/actions | no extra award |
| Lobby / Ended | no reconnect admission | no mutation |

## Automated coverage

`tests/disconnect_reconnect_test.gd` runs at fixed30/60/144 and covers typed transitions,
duplicates/late callbacks, full subsystem freeze, exact2700 boundaries, all phases, exact-once
forfeit, immutable result, wrong/empty/replayed bearer, foreign identity, stale generations,
client self-resume rejection, dropped-ACK retry from a repeated frozen baseline, safe Start
fallback, progress/invulnerability, queue/epoch cleanup and repeated cycles. M16 tests retain
real checkpoint recovery and forged authority coverage.
M17 tests retain warning thresholds: 29/30 enter, deadband, 59/60 clear, stale RTT and bounded
loss/jitter/reorder queues. UI tests exercise EN/RU reconnect/resuming/host-left and focus.

The complete gate is:

```powershell
./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe
```

It discovers/parses every script and retains M0–M21 tests, headless boot, replay hashes,
30/60/144 suites, real-process ENet, the default M17 seeded matrix, series/results, Git
whitespace and isolated cleanup. Final local run:
`builds/validation/m22-full-noexport-final.log` → `M0-M22 validation passed`.

The extended stress command also passed all 13 cases (clean, RTT80/150/200/250, 30/60/144,
combined reconnect/retry, profile change and host drop):

```powershell
./dev_tools/test_network_stress.ps1 -Godot C:/Godot/Godot.exe -Extended
```

Evidence: `builds/validation/m22-m17-extended.log` → `PROJECTVELOCITY_M17_MATRIX_OK`.
Local Windows export is blocked only because this machine has no Godot 4.7.2 export templates;
the failed gate records the exact missing official template paths in
`builds/validation/export.stderr.log`. CI installs templates and owns export/boot acceptance.

## Standalone localhost ENet evidence

All launchers create unique ignored roots/ports, isolated APPDATA/LOCALAPPDATA/logs, bounded
timeouts and clean only owned process handles/cache roots.

```powershell
# Active race reconnect + checkpoint baseline
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Map industrial -Reconnect -DisconnectTick 700 -Port 25025

# Full production 45 seconds / 2700 ticks, no shortened deadline
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -GuestExpiry -DisconnectTick 700 -Port 25026

# Host termination / no migration
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -HostDrop -DisconnectTick 900 -Port 25027

# Immutable final Results reconnect
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Reconnect -DisconnectTick 1900 -Map industrial -Port 25028
```

Observed PASS evidence (ignored local folders):

- active recovery `m15-clean-20-60-a9535be59f0d4af0a20e7ca7bcefc1de`: separate
  processes completed WELCOME → baseline → ack → RESUME once, finished both players and
  converged on winner2, progress7/7 and identical immutable result;
- production expiry `m15-clean-20-60-c0905f4052c043bfa74d6d83edcc2bc9`:
  disconnect start700, deadline3400, exact delta2700; host score1–0, one result reason
  `GUEST_DISCONNECT_TIMEOUT`, no second award;
- host drop `m15-clean-20-60-3945698ce9834473a1ee45c1e74cc400`: guest phase ENDED,
  no migration, zero cleanup queue/history/interpolation/events/projectiles;
- Results recovery `m15-clean-20-60-154c6d9dadba4f45a233f9348fdb6118`: one RESUME,
  final winner2/result retained with no extra score.

Normal OpenGL Compatibility captures were inspected in EN1280×800
`m15-clean-20-60-9108ffe671fa492d989f233d13ccbedf` and RU1920×1080
`m15-clean-20-60-c6827599ea8a4e46a41ab67da2f19be5`. The reconnect panel is centered,
readable, shows role/authoritative seconds and takes priority over connection warnings without
breaking gameplay visibility or focus. These are renderer/presentation evidence, not WAN proof.

## Remaining blockers

No physical WAN/Linux/SteamOS/controller/target-performance certification. Prediction retains
current-world rather than historical dynamic replay. Memory-only credentials deliberately do
not survive process restart. M19 live EOS/Internet remains BLOCKED as stated above. User review
and explicit merge authorization remain required; do not merge or start M23 automatically.
