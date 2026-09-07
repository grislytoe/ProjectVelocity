# Architecture

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
