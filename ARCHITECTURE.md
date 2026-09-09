# Architecture

## M12 settings composition

Bootstrap now owns SettingsRuntime and SettingsSession alongside InputPreferences.
SettingsValues defines schema additions and visual presets; SaveSchema performs the
pure sequential v4→v5 migration. SettingsPage builds AppUI forms, while
DisplayConfirmation routes mouse/keyboard/controller actions through the exclusive modal.
DisplayAdapter owns native window requests/readback/snapshots. SettingsSession owns
detached drafts and the 15-second trial; only successful explicit Apply/Keep persists.
InputPreferences retains debounced device writes but excludes provisional bindings.

SettingsRuntime applies Engine.max_fps, DisplayServer VSync, aspect-preserving Window
scaling, supported canvas texture filters, AudioServer buses and the presentation shader.
PlayerPlaceholder observes visual options and triggers quiet routed SFX; LocalPlayerCamera
adds bounded presentation-only shake without changing its follow model or player state.
AppUI applies text/UI scaling inside a bounded scrollable panel. See SETTINGS.md.
The paragraphs below describe the earlier milestones historically; current save schema is 5.

## Implemented bootstrap

`core/bootstrap/main.tscn` is the composition root. It displays the placeholder and build identity. `AppLogger` is the only autoload; it uses Godot's local rotating log sink. `BuildInfo` exposes constants and engine-derived build flags. `AppConfig` is a typed Resource with a checked-in default. No runtime dependency on Steam or EOS exists.

Build/network identity lives in `core/build/build_info.gd`: `VERSION` (game version), `BUILD_NUMBER`, `NETWORK_PROTOCOL_VERSION` (initially `1`) and `channel()` (DEV/STAGING/RELEASE). The version constants persist in source control and exported scripts; channel derives from engine build/features. Protocol compatibility is versioned independently of release numbering; see NETWORKING.md for bump policy and future handshake use.

## Directory ownership

| Directory | Responsibility |
| --- | --- |
| core/ | Bootstrap, build identity, profile data, application config, logging |
| gameplay/ | M3 controller, movement Resource, contact data and fixed-tick states; future race rules/hazards |
| networking/ | Future transport, prediction, reconciliation, authoritative protocol |
| platform_services/ | Future PlatformService, OnlineService, LobbyService, MultiplayerTransport and IdentityService contracts/adapters |
| ui/ | Presentation and localization; never owns simulation |
| save_system/ | Validated versioned JSON, sequential migrations, staging and backup recovery |
| map_data/ | Future map definitions and modular sections |
| audio/ | Future buses, audio settings, sound assets |
| visuals/ | Independent player animation state machine and procedural placeholder |
| dev_tools/ | Validation tooling; future developer tools and benchmarks |
| tests/ | Dependency-free bootstrap and isolated persistence integration tests |
| docs/ | Master specification and milestone evidence |
| .github/ | CI and pull request template |
| builds/ | Ignored build artifacts and validation logs |
| .tools/ | Ignored local/CI engine downloads |

Unimplemented layers contain a README rather than speculative runtime interfaces. Add the named platform abstractions when their consumers arrive.

## Rendering and timing

Compatibility renderer is the low-end 2D baseline. Physics is fixed at 60 Hz. Base view is 1920x1080, default window 1280x720, canvas-item scaling with preserved aspect ratio. Wider displays receive bars instead of extra competitive visibility. VSync is enabled; simulation rate is independent of presentation. Smooth, non-pixel-art assets are expected. Performance on target hardware is not established by an empty scene.

## Boundaries

Prefer typed Resources, small components, signals, explicit ownership and composition. UI presents state. Gameplay does not call network transport or platform SDKs. Later gameplay and animation state machines remain separate. Standalone multiplayer must never require Steam.

## M1 data and persistence

PlayerProfileData owns typed profile conversion, UUID v4 creation and nickname validation. SaveSchema owns JSON shape/value checks, settings/record foundations and sequential migration. SaveStore owns disk I/O through an injected directory; it never relies on UI or platform SDKs. Bootstrap constructs the store, loads/creates the profile, updates last launch and applies saved language. Future UI can inspect save_store.notification_key and read_only without parsing logs. No new autoload is required.

Production uses user://saves. Tests inject unique OS-cache directories; --smoke-test automatically chooses an isolated store. Profile is the single owner of customization, language and last-input-device data. Settings/record containers are data-only. See SAVE_FORMAT.md for current schema version 2, backup ordering, quarantine and future-version protection.

## M2 input and devices

core/input contains InputBindings (defaults/codecs), InputLayer (Godot event/map adapter and transient intent), InputFrame (consumer snapshot), InputPrompts (glyph-independent descriptors), and InputPreferences (debounced SaveStore adapter). Bootstrap composes these services; they do not own player/gameplay state or call network/platform SDKs. Standard ui_* actions support Godot Control navigation. See CONTROLS.md for lifecycle and ownership.

Schema 2 adds independent keyboard/gamepad overrides, deadzones and prompt-family preferences; M1 saves migrate sequentially and retain their profile and legacy binding foundation. Tests inject synthetic device events and isolated stores. Physical controller validation remains outstanding.

## M3 player controller

`PlayerController` is the CharacterBody2D collision adapter. It accepts an injected InputLayer or InputFrame provider, samples once per physics tick, gathers floor/wall/slope contacts, advances PlayerMotor, and calls move_and_slide. PlayerMotor and its reusable state objects use a fixed 1/60 step and integer tick timers. They do not poll input, access SceneTree, write saves or call network services. Dash direction uses the existing pure M2 quantizer.

`PlayerMovementConfig` is a typed Resource; `default_movement.tres` is the tuning entry point. Treat tuning as immutable during a run. PlayerAnimationMachine and PlayerPlaceholder consume state/events only. Cosmetic poses cannot change simulation. Lifecycle methods expose death/respawn/finish for later modes; M3 does not create hazards, checkpoints or race rules.

The isolated `dev_tools/player_playground.tscn` composes default input, camera, test geometry and localized diagnostic HUD. It never initializes SaveStore and is excluded from staging exports with other dev_tools. See PLAYER_CONTROLLER.md for timing, transitions and tuning contracts; docs/M3_VALIDATION.md for evidence.

## M4 character presentation

The optional controller presentation child receives detached PlayerVisualFrame values; PlayerAnimationMachine no longer receives a PlayerMotor. RobotAppearance validates/copies profile customization, CharacterPresentationConfig owns cosmetic policy, and named RobotPart nodes provide rigid modular art. PlayerPlaceholder owns only transforms/drawing, including readiness cues and local-only preselection. Opponent alpha/nickname/outline are presentation policy; no multiplayer transport is implemented.

Lifecycle notifications publish an immediate visual frame, but visual durations never control the lifecycle. CI compares actual movement with the entire presentation child removed. The developer gallery previews all 14 required poses, local/opponent pairs and in-memory color changes. See CHARACTER_PRESENTATION.md and docs/M4_VALIDATION.md.

## M5 local camera

core/camera contains LocalPlayerCamera (explicit local target and Camera2D adapter), CameraFollowModel (fixed-step copied-value state), and CameraConfig/CameraBounds/CameraZone Resources. The composition root binds one local actor; no player enumeration or networking is involved. Camera updates run after movement and never alter authority. Player relocation is a generic signal, not a camera dependency.

Engine physics interpolation is enabled for matching player/camera render timing. Camera2D native smoothing is disabled in favor of one tested fixed-step smoother. Bounds contain the visible world rectangle at current zoom; priority regions support offset, zoom, look-ahead and temporary position lock. See CAMERA.md and docs/M5_VALIDATION.md. Developer camera fixtures remain excluded from staging exports.

## M6 developer playground

`dev_tools/test_playground.tscn` is the dedicated twelve-station movement fixture. `PlaygroundStation` owns the geometry catalog; `TestPlayground` owns station lifecycle, navigation, diagnostics and a single explicit controller/input/camera. Old collision geometry is removed before the next simulation step. Controller state/input and camera interpolation reset on relocation. Production movement, saves and input schemas are unchanged. See [TEST_PLAYGROUND.md](TEST_PLAYGROUND.md) for station layout and commands. The entire tool and its tests are excluded from staging exports.

## M7 lifecycle composition

The gameplay/race layer owns per-player CheckpointProgress, PlayerLifecycle, shape-based RespawnSafety, reusable DeathZone, CheckpointTrigger, FinishTrigger and transport-free ReadyStart/StartBarrier. PlayerController adds only a death signal and an explicit start lock; unbound M0–M6 movement/replays are preserved. M4 presentation remains an observer and M5 relocation resets are reused. See CHECKPOINTS_AND_LIFECYCLE.md for contracts and map authoring.

## M8 platform modules

Gameplay/platforms owns data-driven static, one-way, moving, temporary and Jump Pad scenes.
PlatformRoute samples absolute 60 Hz ticks; AnimatableBody2D supplies rider transport.
The post-movement surface contact hook delegates pad impulses to PlayerMotor; presentation
remains an observer. RespawnSafety retains moving-body rejection and adds explicit unsafe
support opt-out for temporary platforms and pads. See PLATFORM_MODULES.md for configuration,
collision, timing and future authoring contracts. The developer catalog now has 16 stations.
Milestone task/branch/manual-merge policy is recorded in WORKFLOW.md.

## M9 hazard modules

`gameplay/hazards` contains Resource-driven spikes, saws, lasers and dual-barrel turrets.
Fatal areas extend the M7 DeathZone, including its persistent invulnerability recheck.
Inactive volumes stay reserved for RespawnSafety. No separate death or animation authority
is introduced. The M8 movement/contact refresh behavior is unchanged.

One explicitly composed HazardWorld owns a two-player registry, per-player engagement
leases and a fixed-capacity projectile pool. TurretChannel owns one barrel's fixed-tick
state; TurretConfig lead calculation accepts only value data. Projectiles sweep geometry
and designated-player collision shapes, then return to the pool. Lifecycle signals revoke
old target generations and rounds; station teardown destroys the complete authority.
Physical InputLayer ownership is independent of the targeting registry. Future host
authority can call this boundary; M9 contains no network transport. See HAZARD_MODULES.md.
The developer catalog has 22 stations, with a neutral-input second player in turret tests.

## M10 Solo composition

Bootstrap retains one SaveStore/InputLayer/InputPreferences and adds TrialUI navigation.
SoloTrial owns one disposable SoloCourse and M7 StartBarrier. The course composes M7
PlayerLifecycle/CheckpointProgress, M8 platforms, M9 HazardWorld and M5 camera.
TrialRecords is the validated persistence boundary; TrialRecord supplies integer-tick
validation/formatting. UI observes state/signals and queues navigation outside physics.
See TIME_TRIAL.md for timing, restart ownership, record identity and debug invalidation.

## M11 UI composition

Bootstrap now creates AppUI (a TrialUI subclass) for splash/onboarding and the front end.
IndustrialTheme, RobotPreview, CircuitPreview and the exclusive NameKeyboard are reusable
presentation components. ProfileEdit owns detached transactions through SaveStore;
schema v4 adds an explicit onboarding_complete boolean via v3→v4 migration.
AppUI only applies validated appearance to M4 observers. The M10 trial, checkpoint,
hazard, restart and camera authority is unchanged. See UI_FOUNDATION.md.
