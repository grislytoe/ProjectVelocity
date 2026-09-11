# M15 validation and review

Workspace: `C:/Godot Projects/ProjectVelocity`, branch `feature/m15-network-core`.
Base: approved M14 merge `0e5b923c111fd6c485a28bf76dd2044c52b01120`; fetched origin/dev
matched and its Actions run 34515709814 was successful before branching. No worktree/copy.
User's editor normalization of project.godot was backed up separately and excluded from
the staged file; only the intended application version belongs to this milestone.

Build 0.15.0-dev /21, protocol2 / wire1, save schema5. Training v4 and Industrial v3
reflect the conservative shared code/checksum change. Historical PB keys remain stored;
network composition never loads/saves a player's Time Trial records.

## Automated coverage

`tests/network_core_test.gd` covers malformed/unknown/incompatible/oversize packets, strict
field types/ranges, input transform injection, sequence wrap/duplicates/stale/future/rate
cap/ack, bounded queue/history, full actor state, real-body rewind/replay, explicit 180px
divergence and hard correction, interpolation ordering/relocation/extrapolation hold,
event ordering/dedup/expiry, seeded emulation, MTU fragment reorder/loss/duplicates/limits,
M7 ready/GO/death/respawn/checkpoint/Finish, ownership and both maps' dynamic registry.
It creates/frees host/client world fixtures and checks teardown, with no production save.

`dev_tools/validate.ps1` includes all M0–M14 checks, import and every GDScript parser,
network core at fixed render30/60/144, and the **actual two-process** tests below:

- clean at render caps 30, 60, 144;
- wan profile, snapshots30, explicit disconnect/reconnect;
- Industrial Foundry under stress;
- Training with host-only collision lifecycle fixture.

The process launcher uses real time, never accelerated `--fixed-fps`, separate process
handles, unique isolated APPDATA/LOCALAPPDATA/log directories, local configurable ports,
hard timeouts and `finally` cleanup. It checks handshake scope, movement, remote samples,
GO, monotonically consistent clocks, divergence correction, events and orderly disconnect.
Two actors in one SceneTree are not counted as separate-instance acceptance.

The automated launcher explicitly uses a 600-tick (10-second) heartbeat timeout to tolerate
shared CI runner scheduling stalls; ordinary developer sessions retain 180 ticks (3 seconds).
Reports include the configured timeout and maximum wall-time gap between physics callbacks.
One push CI run disconnected both endpoints before GO under the shorter timeout while the
same commit's PR run passed. This is recorded as a scheduling-sensitive failure, not a pass.
Explicit disconnect/reconnect tests still exercise transport closure immediately.

## Observed Windows evidence

Godot 4.7.2.stable.official.ed1daf0bf, Windows, OpenGL Compatibility on AMD Radeon Graphics.
Representative runs (counts vary with OS scheduling; identifiers refer to ignored local
`builds/validation` folders, not committed images/logs):

| Scenario | Observed result |
|---|---|
| Rendered clean, session prefix c7ba1990 | 350 host snapshots, 349 received; clocks 689/686 ticks, exactly matching host-tick age; RTT2 ticks (~33ms); remote motion on both endpoints; ordinary Jump/Dash/land/death/respawn replicated |
| Rendered lifecycle, prefix 4ab3a7ba | Both endpoints saw 2 checkpoint, 1 Finish, 4 death/hazard, 8 respawn and 1 Start events; guest 308 snapshots; clock age3 ticks |
| Wan30 reconnect, prefix 823824b0 | Both endpoints observed RESUME after disconnect; 232 guest snapshots; host/guest clock350/347; RTT11/17 ticks; bounded final history8 |
| Industrial stress with MTU framing, prefix 422ceb8c | 265 guest snapshots; clock667/658 matched tick age9; RTT13 ticks; final history14; no wire decode errors; 158 corrections and 16 hard snaps including lifecycle/divergence |

The latest correction test additionally verifies hard correction for a divergence injected
after the last saved history sample. Max-error metrics during lifecycle fixtures include
deliberate pit/checkpoint/Finish relocations; they are not clean-network steady-state error.

Inspected normal-renderer screenshots from both endpoints:

- `m15-clean-20-60-a39b821b67ac4e368a1e252a756141fc/{host,client}/screen-{1,2}.png`;
- lifecycle `m15-clean-20-60-cb19b457aa564c45ac57011d7018ebfa/{host,client}/screen-{1,2}.png`.

They show both distinct actors, opponent nickname/30% opacity, local selector/outline,
single local camera, host/client ticks and interpolation/history diagnostics. Two frames
per endpoint complement measured movement; they are not physical WAN evidence.

## Delivery gates and limits

Full local **M0–M15 validator passed**, including all six separate-process scenarios;
output is `builds/m15/full-validation-final.log`. CI runs the same
suite, downloads checksum-verified official templates, exports Windows Staging and boots
both ordinary application and the network developer scene. Local export templates were
not installed; local export is not claimed. Final PR/Actions status is checked at delivery.

Initial CI also passed all six network scenarios, exported Windows and booted the normal
application. Its additional network boot exposed that official templates prohibit CLI
scene overrides. Bootstrap now handles `--local-network` before any save initialization;
the launcher and export smoke use that flag. A separate local two-process regression checks
this entry point; subsequent CI verifies it in the actual export.

Single developer round, default sample profiles/preferences, same-process reconnect,
current-world dynamic replay and snapshot-cadence hazard visuals are explicit limits.
No EOS/M16, production lobby/series/spectator UX, Linux/Steam Deck/physical controller or
physical WAN certification. Stress has visible corrections; no claim of meeting the
150–200ms comfort target. Human two-window play review is required before merge.

Launch and all packet/authority/timing details: [NETWORKING.md](../NETWORKING.md).
Merge remains exclusively user-authorized. Do not begin M16 in this task.
