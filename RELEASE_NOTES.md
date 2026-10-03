# ProjectVelocity 0.25.0-rc.1 staging release notes

This unsigned build31 candidate is for developer review. It is not an approved or public release.

## Included

- Complete standalone Solo flow with RU/EN onboarding, profile/customization, settings and the
  Training Circuit plus 1–2 minute Industrial Foundry Time Trial.
- Data-driven high-speed movement, Double Jump, eight-direction Dash, wall movement, modular
  platforms, hazards, ordered checkpoints, death/respawn, PB/splits and quick restart.
- Keyboard/mouse/controller abstraction, accessible scalable UI, video/audio/control and
  accessibility settings, fixed competitive framing and Compatibility renderer.
- Transport-independent two-player authority, series and reconnect foundations plus local ENet
  development validation. These developer tools are deliberately absent from release exports.
- Portable Windows x86_64 and Linux x86_64 packages; the Linux content also has a SteamOS-friendly
  launcher/layout without a Steam client or Steamworks dependency.

## Compatibility and data

Build identity: 0.25.0-rc.1/build31/STAGING, protocol5/wire4/save5. Training Circuit is v8 and
Industrial Foundry v7; their M24 checksums are unchanged. Versioned JSON saves migrate through
schema5, preserve a previous-known-good backup and recover/quarantine corrupt data. Test or smoke
runs use isolated paths; keep a backup before manual RC testing.

## Known blockers

- Production Online is unavailable. M19 still lacks production EOS Auth/Connect/Lobby/P2P,
  authorized Internet clients and native export acceptance. Local ENet is not a substitute.
- Low-end GTX1050Ti/RX570-class and physical Steam Deck/SteamOS 60 FPS certification is blocked.
- Physical controller/hotplug, clean-machine/distro and full subjective gameplay/UI approval are
  pending the M25 manual sheet.
- Binaries are unsigned portable files. OS warnings are expected; no installer or signing bypass
  is provided. No Steam/store/CDN publishing is part of this candidate.
- Final audio library, some illustrated art/module variety, historical-world network rollback,
  host migration and production Level Editor remain outside this RC.
