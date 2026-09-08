# Player controller — M3

## Running and composing

Open `dev_tools/player_playground.tscn` with F6, or run `godot --path . dev_tools/player_playground.tscn`. The arena contains a flat acceleration lane, ledges, a wall pair, elevated platforms, a 28-degree walkable ramp and a 66-degree sliding ramp. Hold R continuously for one second (60 physics ticks) to reset once. Release R before another reset; leaving the fixture below its bounds also resets at a physics tick. Device prompts follow M2. No save is opened; bindings are defaults for this isolated fixture. Production consumers can inject their configured InputLayer.

Instantiate `gameplay/player/player.tscn`, assign `input_layer` (or a Callable `input_provider` returning InputFrame), and optionally assign a separate PlayerMovementConfig Resource before adding it to the tree. Collision layer 2 is the player; mask 1 is level geometry. The capsule is 32×64 px, about 6% of the 1080px reference view. The adapter requires 60 Hz and rejects invalid tuning. Never call `advance()` from rendering or an arbitrary timer: move_and_slide uses Godot's physics delta.

## Tuning

Edit `gameplay/player/default_movement.tres` in the Inspector. All movement values live on PlayerMovementConfig; defaults are an initial playable baseline, not final balance. Distances use pixels; velocities px/s; accelerations px/s²; public durations seconds. Durations round up to whole 60 Hz ticks. Validate a Resource before using it and do not mutate shared tuning during a run.

| Group | Fields / default behavior |
| --- | --- |
| Ground | ground_max_speed 680; ground_acceleration 4800; ground_deceleration 5800 |
| Air | air_max_speed 660; air_acceleration 2800; air_deceleration 1600 |
| Gravity | rise_gravity 1700; fall_gravity 2300; terminal_velocity 1400 |
| Jump | jump_force 740; second_jump_force 680; coyote_time 0.1; jump_cut_gravity_multiplier 2.5 |
| Wall | wall_slide_speed 100; wall_slide_gravity_multiplier 0.18; wall_jump_horizontal_force 520; wall_jump_vertical_force 720; wall_jump_input_lock_time 0.15 |
| Dash | dash_speed 1450; dash_duration 0.15; dash_momentum_retention 0.65; dash_end_lag 0.06; dash_cancel_enabled false |
| Surfaces | slope_slide_angle_degrees 45; slope_gravity_multiplier 1.2; floor_snap_distance 8; wall_probe_distance 2; wall_normal_max_y 0.15 |
| Lifecycle | respawn_invulnerability 0.75 |

## Simulation rules

- Ground and air approach the requested horizontal speed using their respective acceleration or neutral-input deceleration. Fixed rise/fall gravity and release-dependent rising gravity implement variable jump height. Terminal velocity caps ordinary falling, not active Dash.
- Coyote Time permits a ground-strength jump for six ticks after leaving the floor. One additional jump remains available afterward. There is **no Jump Buffer**: an unsuccessful press is not queued. Duplicate/held jump input is the input adapter's responsibility; the motor consumes edge flags.
- Floor, wall contact, wall slide and wall jump restore the extra jump. Dash refreshes on contact only if that surface contact has not already been used for a Dash; detach and contact again to rearm it. Continuous floor/wall contact and wall-jump input cannot bypass this gate. Wall sliding retains downward gravity with a speed cap; contact probes preserve wall sliding without requiring the player to push into a wall. Wall jump pushes upward/outward and locks horizontal steering for nine ticks. Surface contacts are explicit data so later surface modifiers can be applied before simulation.
- A Dash press with an available charge and nonzero selection overrides existing velocity. The quantized eight-way vector stays fixed for nine movement ticks, with no gravity or steering. Collisions still constrain displacement. On the following tick, configured momentum resumes with gravity and four ticks of steering/action end lag (including the exit tick). Jump cancellation is opt-in and uses an available jump; disabled by default. Dash wins when Dash and Jump are pressed together.
- Preselection is independent of availability; it never auto-fires when an ability refreshes. A successful activation clears InputLayer selection and its local visual indicator. Death/respawn also clear it. A failed activation preserves it. A fresh Dash press can reuse a continuously held direction without releasing WASD/the left stick; holding the trigger never auto-repeats. When using a custom provider, its owner must process the dash_started signal to clear its own stored selection.
- Floor snap and constant slope speed handle walkable inclines. Surfaces above the configured angle are not floors; gravity projected onto the surface causes downhill sliding. Near-vertical normals use the wall rules.

## States and presentation

PlayerStateMachine owns Idle, Run, Jump, Fall, WallSlide, WallJump, Dash, Death, Respawn and Finish, delegating to small reusable state objects. Contacts and vertical speed classify normal movement. Dash and locked lifecycle states override that classification. Inputs are considered once per tick. Timers decay once at the end of that tick.

`die()` freezes movement and clears transient ability timers; `respawn_at(position)` resets motion/abilities/selection and grants 45 ticks of invulnerability; `finish_run()` freezes the finished actor. Respawn exits through one neutral simulation tick. M7 PlayerLifecycle owns the death delay, checkpoint choice and validated Finish; see CHECKPOINTS_AND_LIFECYCLE.md. No timers for race modes, hazards or multiplayer are introduced.

PlayerAnimationMachine is independent: Idle, Run, Jump, Fall, DoubleJump, WallSlide, WallJump, Dash, Landing, Death, Respawn, FinishVictory, Turnaround and Skid. FastFall is a reserved pose only. Procedural placeholders show run cadence proportional to speed, reversal Skid→Turnaround→Run, a max-speed trail, a distinct extra-jump ring, mirrored wall-facing and an eight-direction oriented Dash pose/streak. No squash/stretch. M4 uses detached PlayerVisualFrame snapshots and enforces remote indicator suppression via is_local. See CHARACTER_PRESENTATION.md for modular art, profile colors and opponent policy.

## Determinism and boundaries

The same tick-indexed input/contact sequence produces repeatable local simulation. The actual CharacterBody2D replay is compared at 30/60/144 render FPS, including positions, velocities and states for 720 ticks. This proves render-rate independence for the fixture on the tested engine/platform; it does not promise bit-identical physics across CPUs, OSes or engine versions. Network prediction, rollback, remote input transport and animation replication are outside M3.

No persistence schema changes: save_version remains 2; NETWORK_PROTOCOL_VERSION remains 1. Gameplay does not use a nickname as identity or access platform/network services.
