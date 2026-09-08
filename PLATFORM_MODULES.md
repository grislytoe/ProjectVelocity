# Platform modules (M8)

Author reusable scenes under `gameplay/platforms/`. Each scene exports a typed config
Resource and builds its collision/placeholder polygon from that data. Make a unique
`.tres` for a variant; treat it as immutable during a run. No editor plugin is required.

| Scene | Resource | Contract |
| --- | --- | --- |
| static_platform.tscn | PlatformConfig | Permanent solid polygon; supports slopes |
| one_way_platform.tscn | PlatformConfig | Same adapter with one_way enabled; passage from below |
| moving_platform.tscn | MovingPlatformConfig | AnimatableBody2D carrying CharacterBody2D riders |
| breakable_platform.tscn | BreakablePlatformConfig | Top contact arms warning, disappears, optionally restores |
| jump_pad.tscn | JumpPadConfig | Solid top contact replaces player velocity with launch impulse |

Common fields: `polygon` (local pixels; simple nondegenerate polygon), `color`,
`one_way` and `one_way_margin` (pixels, default 4). Sloped collision uses the existing
PlayerMovementConfig `slope_slide_angle_degrees`; M3 slope rules/tuning are unchanged.
One-way means Godot's local upward collision face; there is no drop-through input.

Moving routes contain at least two finite distinct adjacent points in parent-local
coordinates, relative to the authored platform position. `speed` is pixels/second;
`waits` is empty or contains one nonnegative duration in seconds per point. `reverse`
starts at the last point and reverses traversal. `loop=false` traverses once and stops;
`loop=true, ping_pong=true` returns along the route; disabling ping_pong closes the
route from its final point to its first. Endpoints wait once per visit. Travel and waits
round up to whole 60 Hz ticks, so speed is an upper bound for a segment. Absolute
`PlatformRoute.sample(tick)` avoids accumulated drift and permits future authoritative
time evaluation. Runtime `elapsed_ticks` currently starts when the scene enters the tree.
There is no match clock or network transport in this module.

Breakable defaults: 0.6 s `activation_delay`, `restores=true`, 2 s `restore_delay`.
Only a player's top collision starts the warning (amber); it cannot be rearmed during
the countdown. Collision disappears at the next pre-player physics update after the
tick budget expires. Zero durations still require one tick. The ghost silhouette has
no collision. Restoration retries until the convex hull is clear of player-layer bodies;
it never materializes through a player. `restores=false` stays absent for the scene's
lifetime. Re-enter the playground station to reset its objects; held R resets the player.

Jump Pad `direction` is a nonzero local vector, normalized and rotated into world space;
`force` is velocity magnitude in pixels/second (default 1200 upward). A top impact calls
PlayerController → PlayerMotor, replaces velocity and interrupts Dash/wall locks/lag.
Ordinary M3 air control, gravity, jump-height policy and terminal speed resume on the next
tick. Pads do not independently refill abilities. Death, Finish and start locks reject
launches. A pad is solid and can launch again on a later landing; side impacts do not launch.

The controller dispatches a small `on_player_contact(player, normal)` surface hook after
move_and_slide; presentation never supplies impulses. Modules update at priority -50,
before the player; navigation is -100 and camera stays after the player. Level layer 1
and player layer 2 remain unchanged. Future conveyors/boosts/portals/zones can introduce
their own config and controller contracts without a universal event system now.

RespawnSafety still rejects every AnimatableBody2D, including a paused moving platform.
Breakable surfaces and Jump Pads also explicitly opt out via `unsafe_respawn_support`.
Permanent static/one-way support may pass the existing clearance/fatal overlap check.
Place Start/checkpoint respawn anchors on permanent static ground.

Use the main-folder `dev_tools/test_playground.tscn`, stations 13–16. The original twelve
stations and the M7 lifecycle fixture remain available. F5/staging remains foundation.
