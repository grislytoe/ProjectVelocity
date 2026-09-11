# Networking — M16

M16 requirements extraction: [docs/M16_REQUIREMENTS.md](docs/M16_REQUIREMENTS.md).
Validation and review: [docs/M16_VALIDATION.md](docs/M16_VALIDATION.md).

Two-player host-authoritative **listen host + guest**, in two OS processes. Host is player
1; guest owns player 2. No third server process, SDK, EOS, Steam or third-party dependency.
This is a developer path before online services, not Internet matchmaking.

## Contract and configuration

Master sections 19, 23–24 and 26–33 require 60 Hz physics, 20–30 Hz snapshots, host
authority, prediction/reconciliation, interpolation, synchronized start and dynamic world,
45-second guest reconnect window, 30-second remaining-finisher allowance, no host migration.
The master does not give numeric sequence/history/error/interpolation limits. These are
explicit **M15 defaults**, not quotations from the specification, in `NetworkConfig`:

| Parameter | Default |
|---|---|
| Physics / input sampling | 60 / 60 Hz |
| Snapshot rate | 20 Hz; supported/tested alternative 30 Hz |
| Interpolation / maximum extrapolation | 6 ticks (100 ms) / 3 ticks (50 ms), then hold |
| Input/state history / snapshot buffer | 240 / 32 entries |
| Command queue / admission rate | 12 pending / 90 received per 60 service ticks |
| Command timestamp | host tick -120 through host tick +30 |
| Sequence forward window | 1..240, modulo 65536 |
| Correction epsilon / hard snap | 0.5 / 96 world pixels |
| Visual correction decay | 6 ticks; collision body corrects immediately |
| Liveness / reconnect | 180 / 2700 service ticks |
| Hints / countdown | 180 / 180 ticks |
| Event retention | 120 ticks, 128 retransmitted events, 512 seen IDs |
| Packet / receive work / emulation queue | 65536 bytes / 128 per poll / 256 pending |

Service ticks count fixed physics callbacks even on pause. Host simulation ticks freeze
during reconnect. No OS wall clock controls movement, GO or results. RTT echoes service
ticks; 12 ticks (200 ms) displays the connection warning.

## Transport, wire and identity

`NetworkSession` sends typed `NetPacket` values and consumes `Array[NetPacket]` from the
injected `MultiplayerTransport`. `LocalENetTransport` alone knows ENet. It binds **127.0.0.1**,
admits one guest and decodes before delivery. `NetworkEmulator` wraps this boundary.
No node RPC, network call in movement, received resource path or native object decoding.

Adapter framing splits JSON into <=1000-byte chunks (<=1016-byte ENet datagrams). A 16-byte
little-endian header carries magic `0x50564e32`, uint32 message ID, uint16 chunk index/count,
uint32 total size. Before allocation, validate exact chunk length/count and total <=65536.
At most 32 partial messages live for 60 ticks; 128 recent completed IDs deduplicate replay.
Lost fragments expire without reaching the codec. This avoids ENet oversized-unreliable
packet warnings and keeps simulation independent of datagram MTU.

Protocol **3**, wire revision **2**. Version 1 was M0's identity with no actual wire contract;
the first real wire format is incompatible with it. Increment protocol for incompatible
field order/type, units, authority, ack or required semantics. Compatible fixes retain it.
Save schema remains **5**.

Host creates a random 128-bit session ID and a separate ephemeral reconnect bearer.
Player IDs are session-local 1/2, never nicknames. Local Network creates display-only
profiles; it does not open the user's save or transmit a persistent UUID. The guest keeps
its bearer only in memory and F9 retries that same session. Restarting the application
loses it. Nickname/colors are frozen on accepted entry, including reconnect.

UTF-8 JSON outer array: `[protocol, kind, session_hex, host_tick, payload]`.
The decoder checks exact array lengths, known kind, types, integer ranges, finite numbers,
size, nesting and protocol before any gameplay mutation. Integral JSON floats are validated
before conversion. Session adds direction, scope, map, generation and dynamic-registry checks.
Unknown/malformed/incompatible packets are dropped and counted.

| Kind | Payload |
|---|---|
| 0 HELLO | `[map_id, map_version, checksum, profile, reconnect_bearer_or_empty]` |
| 1 WELCOME | `[reconnect_bearer, snapshot_hz, host_profile, guest_profile]` |
| 2 READY | `[ready_bool, revision]` (monotonic guest intent; retried) |
| 3 INPUT | `[sequence, tick, move_x, move_y, dash_x, dash_y, jump_pressed, jump_held, jump_released, dash_pressed, generation]` |
| 4 SNAPSHOT | `[ack, clock_ticks, start_tick_or_minus1, paused, [host_state, guest_state], dynamics, events, winner_0_1_2, reconnect_ticks, [host_progress, guest_progress], race_baseline]` |
| 5 BYE | `[]`; timeout/transport disconnect is the fallback if lost |
| 6 PING / 7 PONG | `[sender_service_tick]` |

Ticks/generations: 0..2147483647. Session/bearer: 32 hex characters (empty only before
handshake). Map ID <=64 characters, version 1..65535, checksum 64 hex characters. Profile
is `[nickname, body_rgba_hex, accent_rgba_hex]`; nickname uses M1's 3–15 character validation,
colors are exactly 8 hex characters. Both maps pass M13 validation before connecting.

INPUT sequence: 0..65535. Axes finite [-1,1], movement length <=1.001, Dash zero or an
eight-direction unit vector. Four action fields are actual booleans; press/release can
coexist for M2 taps completed within one physics tick. There is **no** player identity, transform, velocity, ability grant,
death or Finish claim in INPUT.

Actor state: `[x, y, gameplay_state, generation, blocked, motor_values]`. Position within
±1,000,000 px; gameplay state 0..9. `ActorState.FIELDS` orders the 16 motor values: velocity,
Double Jump available, Dash available/vector, coyote/wall-lock/Dash/end-lag/invulnerability
ticks, motor tick, movement event mask, requested horizontal, wall side, previous grounded
flag, surface contact mask, spent contact mask. Velocity ±10000, Dash vector components ±1,
timers 0..65535, event mask 0..63, contact masks 0..7. This preserves new-contact-only Dash.

Dynamic row: `[registry_index, type, x, y, a, b, c, d, e, f, generation]`, max 256. The registry is
deterministic tree order from the verified map, not an incoming path. Exact count, indices,
types and state ranges must match before application. Type 0: moving platform (a=elapsed);
1: breakable (a=state,b=remaining); 2: cycle hazard (a=phase,b=elapsed); 3: saw (a=elapsed);
4: turret (a=angle1,b=state1,c=angle2,d=state2); 5: projectile (a=active,b=target ID,
c=vx,d=vy,e=radius,f=lifetime). Unused slots are zero. All numbers finite within ±10,000,000;
phases additionally match enums, projectile active 0/1, target 1/2, radius 0..128.

Event: `[id, host_tick, player_0_1_2, kind, detail, round_id, object_generation]`. IDs monotonically increase for the
session, including across death/reconnect, and are bounded to 31 bits. Legacy kinds 0..12 are
Jump, Double Jump, Wall Jump, Dash, land, death, respawn, checkpoint, Finish, start,
hazard effect, disconnect, resume. Checkpoint detail is its reached count.

## Authority and simulation

| State | Authority |
|---|---|
| Input intent / private Dash preselection | Local InputLayer; selector never sent |
| Collision, abilities, death/respawn, checkpoint, Finish/winner | Host PlayerController/Motor and M7 lifecycle |
| Platforms, hazards, turret hits, projectile caps/pools | Host M8/M9 components |
| GO, tick, clock, pause/reconnect deadline | Host session with ReadyStart/StartBarrier |
| Guest predicted body | Guest prediction, always replaceable by host state |
| Opponent animation/VFX/name/outline | Detached local PlayerVisualFrame presentation |
| Time Trial PB/splits | Offline Solo only; absent from network composition |

Host tick: poll/validate → moving/breakable geometry → one command per guest and local
input → shared PlayerController collision path → hazards/turrets/projectiles/lifecycle →
snapshot if due. M7 Area callbacks observe actual host collisions. Players share Start
and have no mutual collision. Missing input is neutral, including no held movement or
repeated jump/Dash edge. Bursts never simulate extra ticks. Ack advances only on consumption.
Older/duplicate/out-of-order commands are discarded; bounded forward gaps are accepted.

Guest stores input and resulting full motor state. A newer snapshot corrects dynamic
geometry, measures error at the ack state, drops acknowledged history, restores host state
and replays pending input through the **same** `PlayerController.advance`. Replay suppresses
visual signals/publication and live selector clearing. Prediction cannot kill or arm a
breakable; jump-pad impulses use the shared motor. Collision correction is immediate,
small presentation offsets decay, hard corrections reset camera/interpolation. Death,
respawn and Finish generations discard stale history and prior-generation commands.
History overflow rebases instead of replaying incomplete/unbounded history.

Both endpoints buffer opponent state. Ticks are ordered, samples deduplicated, old generations
discarded and relocation clears the buffer. Gaps permit at most 3 ticks extrapolation,
then hold. Guest rejects old authoritative snapshots so they cannot rewind local state/clock.
Remote presentation receives detached state, never a mutable motor or local selector.
Opponent alpha is 30%, weak/absent outline; local actor is opaque with contrast outline.

Events repeat for 120 ticks and deduplicate by session ID/event sequence. Remote movement
flashes wait for the render tick; flashes >12 render ticks late are suppressed. Expired
events never run. Durable state/progress is also in snapshots. Events cannot affect
gameplay or use animation callbacks as authority. Existing placeholder animation/SFX are
recreated locally; no VFX node is replicated.

## Clock, world and lifecycle

After both endpoints load and complete hints, host schedules a 180-tick countdown through
M7. StartBarrier releases on its exact GO tick. Clock advances for each completed race
step including deaths (GO's first completed step = 1 tick). Guest monotonically adopts
snapshot time; display can advance at snapshot cadence. Local pause/restart cannot alter
host time. First valid Finish records the winner and gives the other actor 1800 ticks.

Training and Industrial Foundry use real M13/M14 assemblies. Host ticks all dynamics;
guest disables their gameplay ticks and accepts periodic corrections. Moving platforms
and saws evaluate verified deterministic routes for bounded snapshot age. Breakable, cycle
and turret state comes from host. Guest's ten projectile visual slots never perform hits;
opponent-target alpha is 30%. Host retains 5-per-player / 10-global caps and 1224 px/s tuning.
Rollback uses corrected **current** geometry; it does not rewind a moving world's history.

Guest disconnect freezes simulation and blocks checkpoint/Finish while waiting 2700 service
ticks. F9 authenticates the same process's ephemeral bearer, repeats Ready, validates
checkpoint/Start respawn and resumes. Old-generation input cannot run. Window expiry gives
host the round. Host disconnect ends guest session. Teardown closes ENet and clears packets,
histories/events/buffers; freeing the course releases actors, pools and signals.

## Launch in the main folder

Two PowerShell terminals, both in `C:/Godot Projects/ProjectVelocity`:

```powershell
& C:/Godot/Godot.exe --path . -- --local-network --role=host --port=24715
& C:/Godot/Godot.exe --path . -- --local-network --role=client --port=24715
```

Add `--map=industrial` to both for Foundry (default Training). Host `--snapshots=30` selects
30 Hz; guest adopts the accepted rate. Controls: WASD/left stick, Space/A Jump, Shift/RB
Dash. F8 disconnects; F9 retries on guest. Close both windows to release the port.
No network Quick Restart or local pause. This debug/staging scene bypasses Solo saves;
production Online stays a placeholder. Non-debug builds reject the developer scene.

Bootstrap handles `--local-network` before opening any player save. This also works in
Windows Staging: `./builds/windows/ProjectVelocity.exe -- --local-network --role=host`.
Official export templates disable CLI scene-path overrides, so do not pass a scene path
to the exported EXE. Editor F6 on `networking/local_network.tscn` remains supported.

```powershell
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Profile wan -Snapshots 30 -Reconnect
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Profile stress -Map industrial
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Rendered -Lifecycle
./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe
```

The launcher creates real separate processes with isolated APPDATA/LOCALAPPDATA/log paths
under ignored `builds/validation`, a configurable loopback port and 45-second hard timeout.
Cleanup touches only its exact process handles. Render caps 30/60/144 keep physics at 60.
No `--fixed-fps` in multi-process tests: it independently accelerates headless clocks.
`-Lifecycle` deliberately relocates a host-owned body into actual pit/checkpoint/Finish
collision volumes. It tests event integration, not route skill. Ordinary bots provide
independent movement streams and guest divergence injection.

## Emulation and diagnostics

Inbound shaping applies once per direction. `clean`: no shaping. `wan`: 4±2 ticks one-way,
5% loss, 3% duplication, 15% chance of extra 4-tick reorder delay. `stress`: 6±3 ticks,
10% loss, 10% duplication, 20% reorder. Launcher seeds: 15 host, 29 guest. An explicit
disconnect tick is also available. Same seed+packet schedule produces the same trace;
OS scheduling means whole-process counts vary. These are simulated network conditions.

HUD/logs show role/player/session prefix, host/client ticks, clock, RTT, configured loss,
drops, snapshot age, history depth, correction count/error/hard snaps and buffer depth.
Logs are developer-only and local; no reconnect bearer, full persistent identity, secret
or automatic upload. Launcher reports event counts and actionable stdout/stderr on failure.

Limits: developer round/retry harness, no series/lobby/production results UX; same-process
reconnect; current-world rather than historical dynamic collision replay. Stress can cause
visible corrections; 150–200 ms comfort is not certified. Cycle/turret/projectile visuals
correct at snapshot cadence. Sample profiles/default settings do not read saved preferences.
No physical WAN/Linux/Steam Deck/controller validation is implied. EOS, relay/P2P,
matchmaking/invites and full online UX require a separate authorized milestone.

## M16 wire2 and durable race baseline

Protocol3 is incompatible with protocol2/wire1. Both endpoints must update and create a
new session; protocol rejection happens in the codec before HELLO or state mutation.
No persisted wire state is migrated. Save schema5 is independent of protocol revision.

SNAPSHOT appends `race_baseline` as field10 (eleven fields total):

`[round_id, phase, finish_deadline_or_minus1, complete, accepted_ready_revision, guest_ready,
event_watermark, [host_lifecycle, guest_lifecycle]]`

Lifecycle row: `[ordered_reached_indices, safe_x, safe_y, death_ticks, deaths, finish_ticks_or_minus1]`.
Checkpoint indices address the verified MapDefinition, not names supplied by a guest.
Indices must be unique/in-range, and a strict map requires its exact prefix. This fixes
count-only recovery for maps that disable strict ordering. Actor snapshot carries remaining
invulnerability and movement state. A full baseline restores progress even if old effects
expired; it never grants gameplay authority to a client.

Phase enum: 0 loading, 1 countdown, 2 running, 3 finishing, 4 results, 5 reconnect, 6 ended.
Match clock remains monotonic across retries; each recorded Finish is relative to that
round's GO. World ticks freeze on reconnect, and clock also stops after results.
First host-accepted valid Finish wins; same-tick second Finish retains the first winner,
while both Finish times may be equal. Master only prescribes a draw for tied **series scores**.
Winner camera follows the remaining player until results. No series implementation is claimed.

READY now has `[bool, revision]`; each local ready change increments its revision.
Duplicate/reordered revisions cannot undo withdrawal. Guest F6 toggles Ready; withdrawal
before GO cancels the countdown. Host F7 retries only after results and guest Ready.
Retry clears progress, death/Finish counts, events/history and pools, restores deterministic
phases, then reruns hints/countdown. Entering Results withdraws guest Ready; guest F6 and host F7 confirm the next round.
F8/F9 retain disconnect/reconnect behavior. Ready is a session intent, never a Finish claim.

Every dynamic row appends a generation (eleven values total). Only projectile slots use
nonzero generations: each activation increments it, retirement retains it, reuse never
recycles an old generation. Slot index + generation identifies a projectile. Client rejects
generation rollback and over-cap snapshots, resets interpolation on slot reuse, and never
sets a visual slot active for gameplay. Host retains 5/target,10/global and engagement caps.

Events append round ID and object generation (seven values total). IDs remain session-wide
monotonic; `round_id` scopes presentation. New kinds13–24: skipped checkpoint, platform
break, platform restore, Jump Pad, hazard phase, turret fire, projectile hit, pool return,
round transition, winner, saw hit, laser hit. `detail` is dynamic registry ID for world
effects, phase for round transitions, reached count for checkpoints; generation identifies
the projectile for fire/hit/return. M9's synchronous death retirement may emit pool return
before the confirming hit notification; consumers must never treat effects as lifecycle.
Transient events are deduplicated and discarded outside their round; durable state does
not depend on replaying them. Jump Pad increments actor generation to rebase prediction.

All transports now pass session codec validation, including injected test transports.
Host drops SNAPSHOT/WELCOME from guest before any state/heartbeat write. Thus checkpoint,
death, Finish, winner, phase, turret and hit claims cannot enter a mutation path even if
otherwise valid, duplicated, future, stale or reordered. Unknown/oversize/type-invalid
messages fail codec/framing; diagnostics distinguish wire, scope and command rejections.

Additional real-process tests from the main folder:

```powershell
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Malicious -Map industrial
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Malicious -Map industrial -Profile stress
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Map industrial -Profile wan -Snapshots 30 -Reconnect
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Map industrial -Rendered
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Retry -Map industrial
```

Race fixture runs longer (2400 host /2280 guest service ticks) within the45-second process
timeout, allowing reconnect hints and both actual Finish collisions. It loads the full
official map. Host-only relocations exercise real saw/laser/breakable/Jump Pad/turret and
checkpoint/Finish collisions; these are explicitly not autonomous route completion.
Malicious guest sends every critical event class in forged snapshots through ENet while
honest commands continue. Existing M15 log markers stay stable for tooling compatibility.

Retry acceptance requires a second GO **and consumed new-round guest commands**, with
bounded reconciliation history. Both host command queue and guest sequence reset on the
new round ID. Old-generation input cannot bridge that reset. Moving-support enter/leave
and Jump Pad contact rebase actor generations; current-world replay remains the stated limit.
Within each before/after group, dynamic components retain deterministic map registry order:
the preallocated projectile pool precedes map assembly, so turret shots first sweep on the
next world step. Static fatal volumes and lifecycle run after the dynamic group. No render
callback authorizes a hit, respawn or winner.
