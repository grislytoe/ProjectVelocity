# Local camera — M5

## Run and compose

Open `dev_tools/camera_playground.tscn` and press F6. Its three developer buttons place the player at the default-follow start, a closer ramp zone and a locked platform zone. Colored world rectangles identify the authored zones. Walk across a zone boundary to observe transitions; the buttons deliberately respawn and snap for quick inspection. Existing movement controls and one-second R reset remain unchanged. `player_playground.tscn` also uses the new follow camera with map bounds, without demonstration zones.

Instantiate `core/camera/local_player_camera.tscn` as a sibling of the player and call `follow_local(local_player)` after entering the tree. The composition root supplies the local CharacterBody2D explicitly; the camera never enumerates actors or automatically switches to an opponent. Only one active local camera is intended per viewport, without split-screen. Passing null detaches and freezes the last view. Rebinding disconnects the old relocation signal. No networking, spectator selection or input ownership is added.

## Framing and timing

CameraConfig/default_camera.tres owns all tuning. Default base zoom 1.0 shows the 64px robot at 5.93% of a 1080px reference view. The effective zoom scales with the logical viewport height. The default allowed multipliers 0.85–1.15 keep the robot around 5.04–6.81%, including zones. The existing fixed-aspect canvas stretch preserves this framing at 1280×720, 1920×1080, 2560×1440 and 3840×2160; wider windows retain bars. Deliberately changing the config's zoom limits/reference height can change that design contract.

The camera runs after the controller at physics priority 100, at the same fixed 60 Hz. CameraFollowModel operates on copied world position and velocity; it never writes to the target. Exponential follow, zoom and look-ahead easing use rates per second and a fixed 1/60 step. There is no render-delta feedback into camera or gameplay state.

Project physics interpolation is enabled. Camera2D uses Physics callback mode, also configured before tree entry to avoid engine override warnings. Both the player and camera interpolate between the same physics samples. Built-in Camera2D position/rotation smoothing is disabled to avoid a second smoothing stage. The camera is top-level, ignores rotation and has no inherited player transform.

| CameraConfig field | Default / meaning |
| --- | --- |
| base_zoom / minimum_zoom / maximum_zoom | 1.0 / 0.85 / 1.15 at reference height |
| reference_height | 1080 logical pixels |
| follow_rate | 9 per second |
| look_ahead_rate | 7 per second |
| zoom_rate | 6 per second |
| follow_offset | (0, -70): framing slightly above the player |
| look_ahead_seconds | 0.22 seconds of velocity |
| look_ahead_limit | (180, 70) world pixels, component-wise cap |
| velocity_deadzone | 20 px/s; prevents idle contact noise from steering aim |
| zone_exit_margin | 24 world pixels of exit hysteresis |
| teleport_distance | 1200 world pixels between target samples triggers a safety snap |

Look-ahead follows velocity, including vertical movement, with caps for Dash/falling. Reversal eases through zero; stopping recenters. PlayerController emits a generic `relocated(position)` notification after respawn, letting the camera clear lag immediately. Viewport resize and large external teleports also reset camera/interpolation history. Other teleport owners should call snap_to_target or emit relocated; a small unsignaled teleport is treated as movement. Camera code never determines whether a respawn may occur.

## Bounds

CameraBounds is a Resource containing an enabled flag and an axis-aligned world rectangle. It clamps the complete visible frame using logical viewport size divided by current zoom, both before and after center smoothing. Bounds take precedence over look-ahead, offsets and zone locks. Limits are camera policy only and do not constrain the player's body.

If a map is smaller than the view on an axis, the camera centers that axis without oscillating or inverting min/max. Showing outside that small map is unavoidable at the configured zoom; use an appropriately sized backdrop or author a larger bounds rectangle. M5 does not silently zoom beyond the framing limits to hide it.

## Zone foundation

CameraZone Resources are authored in the camera's zones array. Their rectangles and lock positions use absolute map coordinates. Fields: zone_id, enabled, priority, rectangle, zoom_multiplier, additional_offset, look_ahead_multiplier, lock_enabled and lock_position. Rectangles require positive sizes and all numeric tuning must be finite. Invalid/disabled zones are ignored.

The highest priority eligible zone wins. Equal priority uses lexicographic zone_id ordering, so give zones unique IDs. The active region remains eligible within zone_exit_margin to prevent boundary chatter; a higher-priority region can still override it. Entry/exit ease offsets and zoom through the same follow model. Lock means follow a fixed world point while eligible, not pause gameplay. Leaving the region restores normal follow. A respawn clears hysteresis before selecting the spawn's zone.

This Resource-based foundation can be extended with additional camera-only modifiers or an editor tool. It does not create physics Area2D triggers, camera collision, map streaming, cinematics, shake or automatic spectator behavior.

## Validation

`dev_tools/validate.ps1` runs M0–M5, including model/config/bounds/zone/lifecycle tests and three real-controller camera replays at 30/60/144 FPS. Both camera traces and gameplay traces must match across rates. Gameplay also matches the approved replay without a camera.

For rendered motion: `godot --path . --fixed-fps 144 --script dev_tools/camera_motion_smoke.gd`. It tracks a magenta marker attached to a steadily running CharacterBody2D after the follow transient settles. Peak-to-peak screen displacement across 32 rendered frames must be at most 1.5px. The local run measured 0px. An intentional `-- --negative-control` disables player interpolation and fails with 7px, demonstrating sensitivity to camera/player timing mismatch. This is an expected diagnostic failure, not a normal validation command.

`godot --path . --script dev_tools/camera_scene_smoke.gd` captures default/zoom/lock views and checks framing. Screenshots/logs live under ignored builds/validation. These tests do not prove absence of driver stutter or establish subjective camera comfort on every device. Physical gamepad and target-hardware review remain outstanding.

Godot's timing rationale is documented in [Fixing jitter, stutter and input lag](https://docs.godotengine.org/en/stable/tutorials/rendering/jitter_stutter.html) and [2D physics interpolation](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/2d_and_3d_physics_interpolation.html). Runtime validation targets the pinned Godot 4.7.2 executable.
