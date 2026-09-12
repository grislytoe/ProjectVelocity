# M16 requirements and implementation decisions

Read against the complete gameplay/network sections of MASTER_SPECIFICATION.txt and the
approved M15 NETWORKING.md. This milestone extends NetworkSession/NetworkCourse, the codec,
prediction, ENet adapter and emulator. It introduces no second networking architecture.

| Master sections | Required behavior / implementation contract |
|---|---|
| 7–15 | Existing M3 movement and fresh-contact Dash; M7 ordered per-player checkpoints with map opt-out, mandatory Finish, no teleport on skipped Finish; 27 death ticks, safe checkpoint/Start, zero temporary movement, 45 invulnerability ticks; timer continues |
| 16–17 | Moving route points/speed/waits/direction, breakable delay/disappearance/restoration, solid one-way collision and Jump Pad impulse; deterministic saw and laser phases with telegraph; no unsynchronized randomness |
| 17, M9 review override | Two turret channels, detection/LOS/aim/telegraph/fire/cooldown; 1224 px/s target-bound swept projectiles, pool mandatory, 5/target, 10/global, default 3 engagements/target; full ordinary cooldown on cap, no queued shots; remote-target alpha 0.3, local reuse 1.0 |
| 19–21 | Both endpoints verify map ID/version/checksum through M13; real M14 Industrial Foundry, seven mandatory checkpoints, shortcuts unchanged; all 22 playground stations retained |
| 22–25 | Own camera, no mutual player collision, local opaque/opponent 0.3, frozen display profile; no online Solo PB/splits or production save access |
| 26–29 | Host input simulation at 60 Hz; 20/30 Hz snapshot; full motor reconciliation and bounded interpolation; host exclusively owns death/checkpoint/Finish/winner/dynamics/clock/hit; events recreate presentation only |
| 31–32 | Loaded/hints → Ready → host countdown → exact GO; first valid Finish wins, 1800 ticks for remaining player; winner spectates; Results and both Ready before host retry; reset canonical map/gameplay |
| 32 tie wording | Master specifies **series score draw** after the last configured round, no tiebreaker. It does not specify sub-tick photo finish or a draw for same-tick round Finish. M16 uses first host-accepted valid collision callback, ordered by authoritative event sequence; equal tick times remain equal, first winner cannot be overwritten. No invented series scoring is included |
| 33 | Guest disconnect freezes world/clock; 2700 service ticks reconnect; host checkpoint/Start respawn, never guest history; finished guest stays finished after safe relocation; expiry awards host, host loss ends guest; no migration |
| 34–45 | Developer diagnostics include round, progress, deaths, pool/events/rejections; existing M11/M12 Solo UI/settings remain intact; diagnostic checkpoint counts are not a new permanent production HUD |

M15's numeric bounds not fixed by master are retained: input queue12, history240, buffer32,
input90/s, timestamps -120/+30, event120 ticks/128 retained/512 seen, interpolation6 ticks,
extrapolation3 then hold, packet65536, poll128 datagrams, emulator256. Intent admission is
also bounded at90/s; forged server-to-client packets fail direction before heartbeat or state.
Invalid packets are dropped/counted, not grounds for automatically banning an honest session.

Host order remains poll/admit → moving/breakable geometry → one input per actor and real
CharacterBody collision → hazards/turrets/swept projectiles → M7 lifecycle → snapshot.
Area2D callbacks use host physics overlaps and blocked/locked lifecycle guards. Frame/render
delay never determines collision acceptance or the authoritative match clock.

Static and one-way platforms and Jump Pad configurations are covered by map identity;
they have no mutable network phase. Moving, temporary/breakable, saw, cyclic/triggered
hazard, turret and pooled projectile state use the existing deterministic map registry.
Jump Pad contact emits an event and rebases the actor generation. Reconciliation suppresses
one-shot publication; clients cannot arm platforms, kill actors or run turret/projectile hits.

Protocol3/wire2 is required by changed READY, snapshot, event and dynamic row schemas.
Protocol2 is rejected; there is no cross-version reconnect or in-place wire migration.
Save schema5 remains unchanged. Training v5 / Industrial v4 checksum bumps reflect shared
gameplay code; historical PB keys are preserved, never relabeled as a compatible map.

Scope ends at round/retry developer networking. EOS compatibility work, SDK/P2P/lobbies,
matchmaking, production series/results UI and online services remain separately authorized
work. No M17 work, host migration, platform certification or WAN certification is implied.
