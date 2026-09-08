# Hazard modules (M9)

Offline, fixed 60 Hz, no networking or event bus. Scenes live in `gameplay/hazards/`;
the existing `gameplay/race/death_zone.tscn` remains the single fatal Area2D base.
All hits call `PlayerController.die()` and respect invulnerability and Finish. M7
PlayerLifecycle remains responsible for respawn; presentation never authorizes damage.

## Authoring

Assign a unique Resource to a scene instance for variants. Treat tuning as immutable
after entry. Durations are seconds rounded upward to whole physics ticks; dimensions,
ranges and offsets are pixels; speed is pixels/second; angles are radians. Invalid
configs fail scene initialization with an explicit error. No editor plugin is required.

| Scene / Resource | Modes and fields |
| --- | --- |
| race/death_zone.tscn / authored collision shape | Reusable fatal area; `lethal` gates damage, layer 4 reserves respawn volume |
| spikes.tscn / SpikeConfig | STATIC, TIMED, TRIGGER; size; inactive_duration 1.5; telegraph_duration 0.5; active_duration 1; phase_offset 0 |
| laser.tscn / LaserConfig | PERMANENT or CYCLIC; same phase fields; default size 18×240 |
| saw.tscn / SawConfig | radius 36; moving false; path MovingPlatformConfig with route/speed/waits/loop/ping_pong/reverse |
| turret.tscn / TurretConfig | Two independent player-ID channels and barrel config overrides; details below |
| HazardWorld / HazardCapsConfig | One shared authority and preallocated pool per active map/station |

Spike `size` defaults to 100×24. Timed hazards cycle INACTIVE → TELEGRAPH → ACTIVE.
Amber is nonlethal, red is lethal, dim outline is inactive. Static/permanent modes are
always active. Phase offset advances the starting cycle; it has no effect on static
or triggered modes. An initial phase can intentionally place a cyclic hazard mid-cycle.

Local trigger mode accepts `set_trigger(bool)`: rising edge starts the full warning;
held true stays extended; false retracts immediately on the next fixed tick. Another
rising edge must warn again. `initially_triggered` supplies the initial switch state.
Optional `trigger_on_player_overlap` builds a local player sensor; `trigger_size`
(220×100) and `trigger_offset` (-140,-40) configure it. When enabled, live player
occupancy owns the switch state. The cyan sensor rectangle is nonfatal. No universal
level event system is introduced.

Saw routes reuse M8's absolute tick sampler. Points are relative to the authored origin
in parent coordinates. Saw radius describes the complete circular damage shape.
Author units with unit scale; rotate lasers/spikes for alternate orientations. Hazard
Area2D shapes stay on layer 4 during inactive phases, conservatively excluding future
activation volumes from Start/checkpoint clearance. Moving/temporary supports remain
ineligible under M7/M8 rules. Place anchors on clear permanent ground outside saw routes.

## Turrets and authority

Create one `HazardWorld`, add it to the map, then `register_player(stable_id, actor)`.
The offline roster supports two distinct actors/IDs. Registering an actor does not
assign InputLayer: each actor can use its own InputFrame provider, and only the local
actor uses physical input. Create a Turret, `bind(world, [id_one, id_two])` before adding
it to the tree. An absent second ID leaves its barrel idle and permits solo testing.
Use the same authority for every turret in the map so global caps have one owner.

One base has two barrel offsets (-12,-14)/(12,14). Each barrel owns DETECTION →
LINE_OF_SIGHT → AIM → TELEGRAPH → FIRE → COOLDOWN. Config defaults are shared;
`barrel_one_config` and `barrel_two_config` independently override weapon tuning.
The base config owns barrel placement. Both barrels can fire in one physics tick.

Defaults: detection_range 1100, fire_range 900, aim_turn_speed 3 rad/s,
aim_tolerance 0.06 rad, telegraph_duration 0.5 s, cooldown 1 s,
minimum_cooldown 0.25 s, projectile_speed 816 px/s (120% of 680 base run speed),
projectile_radius 5, projectile_lifetime 5 s, aim_lead_factor 0.7,
maximum_lead_time 0.5 s, maximum_lead_distance 180 px. All values are Resource fields.
Effective cooldown is max(cooldown, minimum_cooldown). Fire range cannot exceed detection.

LOS tests level collision layer 1 before aiming and throughout warning/fire. Velocity
lead uses distance/speed travel time, time cap, lead factor and displacement cap. Aim
turns at the configured maximum rate. The warning locks the barrel direction; the shot
follows that visible line, allowing evasion. Leaving fire/detection range, losing LOS,
death, Finish, relocation or target removal cancels warning and releases engagement.

An engagement lease covers AIM/TELEGRAPH/FIRE. Default maximum is three turrets per
target, configurable through `engaging_turrets_per_target`; the other player's leases
are independent. Cooldown releases the lease. Waiting turrets retry LOS/acquisition on
later ticks; no shot is queued. Evaluation order is scene physics order, not a fairness
scheduler. Author future synchronized ordering at the authoritative simulation boundary.

## Projectile lifecycle and caps

HazardWorld preallocates exactly `projectiles_global` objects (default 10). Default
`projectiles_per_target` is 5. Config caps are snapshotted on entry; recreate the authority
to change pool capacity. Resource validation bounds authorable capacities to 200 global,
100 per target and 32 engagements per target. Pool occupancy never allocates new nodes.
If either projectile cap is reached, skip that shot and enter ordinary cooldown. A freed
slot cannot trigger a deferred burst.

Each active round stores target_player_id, source turret ID, velocity, radius and lifetime.
It is ballistic, not homing. Swept circles query geometry and the designated player capsule,
ignoring all other player-layer bodies. Geometry limits the target sweep so shots cannot
kill through a wall, including at high speed. Other players remain visible and unharmed.
An invulnerable hit is unconfirmed: the round continues unless geometry blocks it.

Return on world collision, confirmed target hit, lifetime expiry, target death/Finish,
removal/relocation, or source turret removal. Death retires the entire target's old rounds
immediately. Clear IDs, motion, lifetime, position, visibility and cast exceptions on reuse.
Target generations invalidate in-progress channel state without retaining deleted actors.
Destroying the authority releases registrations and frees every pooled child. Pool ownership
is scene-local, never an autoload. No real save or transport interface is opened.

## Developer review

Main folder only: `C:/Godot Projects/ProjectVelocity/dev_tools/test_playground.tscn`.
Stations 17–22 exercise DeathZone; static/timed/sensor spikes; static/path saws;
permanent/cyclic lasers; dual barrel targeting; and four-turret caps with deliberately
slow rounds. The idle second actor uses neutral input, independent lifecycle and identity.
HUD shows phase, channel state/ticks, engagement occupancy, per-target/global pool counts
and skipped shots. The cap fixture overrides speed/cadence for visibility; production
defaults remain in Resources. R/top face held one second resets the local player;
reselecting a station recreates every hazard, opponent, lease and pool.
