# Architecture

## M21 Online Match / Series

`OnlineSeries` is the typed, transport-independent state owner for the complete two-player
series lifecycle. `NetworkSession` remains the only simulation/network authority and invokes
that model after verified M7 checkpoint/Finish signals; no parallel race authority exists.
The model owns immutable map/settings identity, session/series/round generations, loaded and
between-round Ready revisions, host start/deadline ticks, per-round evidence, score, best times
and final winner/Draw. `RaceBaseline` carries a validated copy in every authoritative snapshot.

Protocol4/wire3 adds generation-bound LOADED/READY/action payloads, generation-bound INPUT,
expanded WELCOME settings identity and the complete series baseline. Incompatible protocol3
peers fail codec/handshake admission. Save schema5 and official map identities are unchanged.
LocalENetTransport is still only a development adapter; gameplay consumes MultiplayerTransport.

`OnlineMatchOverlay` presents RU/EN controls/results/actions and reads snapshots only. The
spectator target switch is confined to LocalPlayerCamera/NetworkCourse presentation and cannot
move actors or validate results. Production Online continues to construct the unavailable M20
client because M19 native EOS prerequisites remain blocked; local ENet acceptance is not EOS.
See [M21 validation](docs/M21_VALIDATION.md) and [network contract](NETWORKING.md).

## M19 policy delivery — live integration BLOCKED

`core/online` separates JoinCode, LobbyPolicy, LobbyService operation coordination,
OnlineService identity state policy and EOSCapability. None initializes a native SDK.
`networking/eos_p2p_transport.gd` implements MultiplayerTransport policy only via an
explicit debug non-live fixture boundary; production open returns unavailable. It cannot
be substituted for accepted native EOS transport in game composition. Existing simulation,
emulator and ENet remain independent. M11 shows a localized unavailable screen with Back focus.
See [ownership and unresolved native boundary](docs/M19_EOS_INTEGRATION.md). No secret or
persistent identity storage, third-party dependency, new autoload or vendor patch is added.

## M18 critical dependency gate

M18 adds only an explicitly invoked native capability probe and archive/CI tooling under
dev_tools. No EOS autoload, production transport adapter or core EOS reference is added.
The probe dynamically loads an inspected official2.3.0 native subset into its own process;
ordinary startup/ENet stays independent. Native SDK lifetime is process-wide: the observed
post-shutdown reinitialization fails; scene/platform lifecycle remains unproven.
See [M18 BLOCKED report](docs/M18_COMPATIBILITY.md) before any full plugin integration.

## M15 network composition

`networking/local_network.tscn` composes InputLayer, default SettingsRuntime/WorldPresentation,
NetworkCourse, NetworkSession and a loopback transport wrapped by NetworkEmulator. It opens
no SaveStore/TrialRecords. NetworkCourse reuses SoloCourse's assembly and M7/M9 primitives,
registers both players and disables independent component ticks; host schedules them in
fixed order. Guest predicts its owned PlayerController. Explicit authority/replay guards
default to prior offline behavior. Both maps and all 22 playground stations remain available.

MultiplayerTransport exposes typed packets. ENet appears only in LocalENetTransport;
PacketFragments bounds MTU-sized wire assembly. InputCommand/ActorState/NetPacket validate
intent and rollback/wire values. CommandQueue, PredictionHistory, SnapshotBuffer and
GameplayEvents independently own bounded state. Host owns collision, lifecycle and time;
presentation observes detached frames. See NETWORKING.md for schema and limitations.

Main bootstrap dispatches the development `--local-network` flag before save initialization.
This supports official export templates, which disable CLI scene-path overrides.


## M12 settings composition

Bootstrap now owns SettingsRuntime and SettingsSession alongside InputPreferences.
WorldPresentation renders Solo through a SubViewport at the selected resolution budget,
with a fixed 1920×1080 logical view and an independent native-resolution UI canvas.
Display selections and window resizing start at 1280×800; bootstrap upgrades legacy
lower display values without replacing the save document.
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

## M13 map composition

Map Data owns MapDefinition, section definitions/placements, route point resources,
MapCatalog, MapValidator/MapDiagnostics and PV-MAP-1 canonical identity. Gameplay/maps
MapAssembly owns section instances. SoloCourse owns actor/lifecycle/trigger/camera/pool
composition; SoloTrial owns preflight, first-physics safety and atomic failure teardown.
UI selects catalog definitions and presents localized errors and preview metadata.
No second checkpoint authority, network adapter, editor or streaming system is added.
All 22 developer playground stations remain available. See MAP_FORMAT.md and
[map authoring](docs/MAP_AUTHORING.md). The developer overview is
res://dev_tools/map_framework.tscn; tests and tools remain excluded from exports.

## M14

M14 adds industrial_foundry through the existing MapCatalog/MapAssembly/SoloCourse path. Eight serialized scenes use M8/M9 modules. MapDefinition camera bounds/zones are validated, hashed and injected into M5. No movement, network, streaming or save authority changes. See docs/M14_INDUSTRIAL_TRACK.md.
## M16 network race extension

`NetworkSession` remains the only network simulation owner. `RaceBaseline` adds strict,
durable per-player lifecycle/round data to its snapshots; `NetworkCourse` still composes
the real M7/M8/M9 and M13/M14 world. M9 projectiles expose fire/return/confirmed-hit signals
and monotonic pool generations, without any dependency on transport. Host consumes these
signals into round-scoped gameplay events; guest reconstructs effects and cannot authorize
state. Ready revisions prevent reordered intent, host retry restores canonical map/pools,
and moving-support/Jump Pad transitions rebase existing prediction generations. See
[NETWORKING.md](NETWORKING.md) and [M16 requirements](docs/M16_REQUIREMENTS.md).

## M17 development network stress boundary

NetworkConditionProfile validates/copies condition data; NetworkEmulator is still the sole
MultiplayerTransport decorator around LocalENetTransport. Application messages receive
inbound delay/loss/dup/reorder and independent outbound loss, with60Hz service scheduling.
Fractional tick error diffusion preserves exact mean ms and leaves physics/snapshot rates alone.
No wire fields or gameplay/map/checksum code changed. BuildInfo0.17.0-dev/23 retains protocol3/wire2.

NetworkTelemetry observes the developer composition without owning a session reference or
changing gameplay state. PredictionHistory and SnapshotBuffer add bounded diagnostics only.
The composition handles local profile selection, drop/reconnect and reports in isolated runs.
The warning is a local UI observer of existing tick-echo RTT. No SaveStore/TrialRecords,
production setting, upload or service dependency is introduced. Schema and units are documented
in NETWORKING.md; evaluator compares existing host-authoritative race fixture outcomes.

## M20 Online Lobby UI

M20 adds AppUI-owned LobbyPage and a detached LobbyClient/LobbyView/MatchSettings presentation port. Production capability remains unavailable; the test-only executor is excluded from exports. Generation/request IDs and host revisions protect asynchronous UI updates. M16 remains gameplay authority. See [M20 contract](docs/M20_VALIDATION.md).
