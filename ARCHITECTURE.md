# Architecture

## Implemented bootstrap

`core/bootstrap/main.tscn` is the composition root. It displays the placeholder and build identity. `AppLogger` is the only autoload; it uses Godot's local rotating log sink. `BuildInfo` exposes constants and engine-derived build flags. `AppConfig` is a typed Resource with a checked-in default. No runtime dependency on Steam or EOS exists.

Build/network identity lives in `core/build/build_info.gd`: `VERSION` (game version), `BUILD_NUMBER`, `NETWORK_PROTOCOL_VERSION` (initially `1`) and `channel()` (DEV/STAGING/RELEASE). The version constants persist in source control and exported scripts; channel derives from engine build/features. Protocol compatibility is versioned independently of release numbering; see NETWORKING.md for bump policy and future handshake use.

## Directory ownership

| Directory | Responsibility |
| --- | --- |
| core/ | Bootstrap, build identity, profile data, application config, logging |
| gameplay/ | Future movement, race rules, hazards; no service SDK calls |
| networking/ | Future transport, prediction, reconciliation, authoritative protocol |
| platform_services/ | Future PlatformService, OnlineService, LobbyService, MultiplayerTransport and IdentityService contracts/adapters |
| ui/ | Presentation and localization; never owns simulation |
| save_system/ | Validated versioned JSON, sequential migrations, staging and backup recovery |
| map_data/ | Future map definitions and modular sections |
| audio/ | Future buses, audio settings, sound assets |
| visuals/ | Future character presentation, animation and VFX |
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

Production uses user://saves. Tests inject unique OS-cache directories; --smoke-test automatically chooses an isolated store. Profile is the single owner of customization, language and last-input-device data. Settings/record containers are data-only. See SAVE_FORMAT.md for schema version 1, backup ordering, quarantine and future-version protection.
