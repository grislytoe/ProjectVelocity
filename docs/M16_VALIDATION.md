# M16 validation and manual review

Workspace: `C:/Godot Projects/ProjectVelocity`; branch `feature/m16-networked-race-hazards`.
Base: approved dev `ad24a27bb1c0a9e23f22c6293873ad403b68a274`, fetched and matched origin/dev.
Its Actions run34570907028 completed successfully. No worktree or duplicate checkout.

Runtime build **0.16.0-dev /22**, protocol **3 /wire2**, save schema **5**.
User-owned project.godot is preserved byte-for-byte, excluded from the commit:
SHA256 `5B9713ACA5045DD697EA09DF21E9DE658283B782B3B0C8F2CC540539FABB65AC`.
Consequently its editor application/config/version metadata still says0.15.0-dev;
BuildInfo is the M16 runtime identity. This explicit preservation exception replaces the
old version-equality test; no unrelated editor normalization is staged.

## Automated scope

`network_race_test.gd` repeats full Industrial assembly/teardown three times and checks:
every critical event class forged as a snapshot, duplicate/stale/future claims leave the
serialized authoritative gameplay baseline unchanged; wire3 roundtrip and wire2 rejection;
strict field types, map checkpoint indices, ready withdrawal/reorder, exact GO, independent
mandatory progress, safe death/respawn/immunity, bearer reconnect with host-owned progress,
first-valid/same-tick Finish ordering, host retry and canonical phases, drift correction,
pool slot generations, opacity, per-target/global caps and shutdown buffers.

M15 tests remain enabled (codec/input/ack/rate/MTU, real collision prediction, bounded
interpolation/events and maps). Existing M7/M8/M9 suites exercise geometry, swept hits,
target channels, thin wall blocking, invulnerability, cap/cooldown and repeated pooling.
The full validator retains M0–M15 checks/replay hashes and adds M16 at render30/60/144,
three true process scenarios and an exported Windows process scenario in CI.

Each localhost run starts two separate Godot processes through the real ENet adapter,
isolates APPDATA/LOCALAPPDATA/log paths, limits process lifetime and cleans owned process
trees in `finally`. No real saves or persistent user UUID are accessed. Frame-cap tests
retain physics60; headless process tests do not use accelerated `--fixed-fps`.

## Observed Windows evidence

Godot4.7.2.stable.official.ed1daf0bf; Windows/OpenGL Compatibility. Representative measured
runs below are local/seeded emulation, not physical WAN. Counts vary with OS scheduling.
Round clocks converge to1411 ticks; both actors Finish, winner2, progress7/7. Both endpoints
observe14 checkpoint events,2 Finish, saw hit, permanent laser hit, Jump Pad, platform break,
turret fire and a confirmed projectile hit. Host pool peak2/10 and final active0.

| Scenario / ignored run folder | Guest snapshots / corrections / hard snaps | Rejection/dedupe observations |
|---|---|---|
| Rendered clean malicious `m15-clean-20-60-0004b813d0dc4d6c9410529125599085` | 699 /47 /24 | 1722 forged claims sent;1753 host scope/generation rejections;8938 repeated event deliveries suppressed |
| Stress malicious `m15-stress-20-60-fb3227a20cc6440b9e4b5b96bb6544b1` | 483 /117 /35 | 1428 forged claims;1723 host scope/generation rejections;6482 suppressed duplicate events |
| Wan30 reconnect `m15-wan-30-60-b79a49d4f7d745899195a1682b2e560e` | 770 /152 /28 | Host-authorized RESUME,14 checkpoints/2 Finish on each endpoint;10525 repeated events suppressed |

Rejection counters also include obsolete actor generations, so they are not a one-to-one
count of forged messages. Network drops/duplication alter delivered claim counts. Max
correction distance in fixture reports includes deliberate map-wide host relocations and
the injected180px guest divergence; it is not steady-state latency error.

The initial full validator reached its final M16 wan/reconnect scenario but failed because
the original1980-tick guest limit ended before the host's second-player Finish fixture
after reconnect hints. This was a test-duration failure, not recorded as a pass. Extended
M16 runs to2400/2280 service ticks; targeted rerun passed.
CI runs34610475300 and34610476607 later hit the original45-second process deadline
in different M16 scenarios. A40-second physics fixture had insufficient runner scheduling
headroom. M16 now allows90 seconds per process; M15 retains45 seconds. Gameplay assertions
and owned-process cleanup remain intact. The full local e2c015c2 run passed
(`builds/validation/m16-final-sha.log`) before this launcher-only timeout adjustment.
The complete local M0–M16 run passed (`builds/validation/m16-full-final.log`). Subsequent
retry checks exposed and fixed a real new-round command-sequence bug: host reset its queue
while guest retained the previous round sequence. Guest now rebases sequence/history when
the round baseline changes. A regression test checks this on an independent client world.

Final targeted retry run `m15-clean-20-60-20ec2d0fddac422f819cc408c030fb8c` reached round2
on both endpoints, consumed guest sequence111, rejected0 commands and ended with guest
history4 and pool active0. The launcher now requires consumed input after second GO, not
merely a round2 state. Its report preserves the last simulated ack across disconnect cleanup.

F9 now confirms return even if Results had cleared Ready. A separate real-process Results
reconnect (`m15-clean-20-60-6be18af389be41bdbba8ff75153f75e8`, disconnect tick1900) passed:
both endpoints retained clock1411, winner2, progress7/7, exactly2 Finish and1 RESUME, pool0.
This case is included in the full validator alongside running-round reconnect.
The complete delivery-tree local run also passed (`builds/validation/m16-delivery-head.log`)
before this focused reconnect fix; the fix has its own race regression and process pass.

Normal renderer captures from the rendered run were inspected for both endpoints, actual
saw death, respawn immunity, breakable contact, remote alpha/name and winner spectating.
Geometry crossed under diagnostics in the initial captures; M16 adds an opaque dark HUD
panel and invulnerability/hazard-phase readouts. Final panel/laser/turret/results/second-GO
captures were inspected in `m15-clean-20-60-70efaadcf798416193432284202e1a98/{host,client}`.
Both endpoints show local/remote distinctions and the new baseline. Capture paths remain
ignored local evidence. The exact delivery commit also runs the complete CI suite.

## Manual review from the main folder

Recommended: launch both interactive windows with one command. This avoids a terminal
waiting for the first Godot process before launching the second, and keeps logs separate:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\dev_tools\start_local_network.ps1 -Godot C:/Godot/Godot.exe
```

Keep both windows open. First-round Ready is automatic; F6 toggles it off/on. The HUD
distinguishes waiting for a peer, handshake, hints, guest readiness and countdown.
Movement is enabled only after GO, using A/D, Space and Shift in the focused window.
The launcher supports Windows PowerShell5.1, opens visible game windows and restores the
caller's environment after assigning isolated child log/save paths. Its rendered two-process
check reached GO on both endpoints. Manual review confirmed movement and approved the
large centered3/2/1/GO overlay; it uses the existing host tick and hides GO after60 ticks.

Open two PowerShell terminals in `C:/Godot Projects/ProjectVelocity`:

```powershell
& C:/Godot/Godot.exe --path . -- --local-network --role=host --port=24715 --map=industrial
& C:/Godot/Godot.exe --path . -- --local-network --role=client --port=24715 --map=industrial
```

1. Both load the real Foundry, complete hints and start at common host GO; move independently.
2. During countdown guest F6 withdraws Ready; F6 again allows a fresh countdown.
3. Check local opacity/outline, remote30%/nickname, moving/one-way/breakable support,
   Jump Pad and laser telegraph; take a fatal hit and check safe checkpoint respawn/immunity.
4. Guest F8 disconnects; host world/timer freeze. Guest F9 reconnects using its in-memory
   bearer and resumes from host progress. Restarting the guest process does not retain bearer.
5. Finish after all mandatory checkpoints; winner spectates the remaining player. Second
   Finish or the1800-tick allowance produces Results. Guest F6 Ready, host F7 retries;
   progress/pools/phases reset and both enter another countdown.
6. Close both windows, run offline Solo and verify unchanged UI/settings/PB behavior.

Reproducible adversarial/collision fixture (not a route-playing bot):

```powershell
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Malicious -Map industrial -Rendered
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Malicious -Map industrial -Profile stress
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Map industrial -Profile wan -Snapshots 30 -Reconnect
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Retry -Map industrial
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Reconnect -DisconnectTick 1900 -Map industrial
./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe
```

The host fixture uses actual map collision volumes to reject early Finish, kill via saw and
laser, contact a breakable/Jump Pad, expose a target to a real turret, visit all checkpoint
triggers and finish both players. No injected guest checkpoint history is ever authoritative.

## Limits and delivery gate

Transport remains127.0.0.1 only. No physical WAN, Linux, Steam Deck, physical-controller or
low-end-performance certification. No EOS/Steam/lobby/matchmaking/M17 or host migration.
Production series/results UX is outside this developer round path. Movement prediction
still replays against corrected current world geometry, not a historical world rewind;
moving-support contact changes and Jump Pad/lifecycle relocations rebase actor generation.
Stress can produce visible corrections;150–200ms comfort is not certified.

Local export templates are absent. CI downloads checksum-verified official templates,
exports Windows Staging, verifies both map identities and ordinary/network boots, then
runs actual exported host/client processes. No local export pass is claimed.
Run34611781918 passed all editor process scenarios, export and both boot smoke checks,
then exposed a launcher error: official export templates reject `--path`. The exported
process scenario now explicitly uses `-Exported`, loading the EXE's adjacent pack without
a project path override; editor launches retain the explicit workspace path.
User manual review and explicit merge authorization remain required. Do not merge or start M17.
