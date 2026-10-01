# Character presentation, animation and effects

M23 adds the shared `ArtPalette`, procedural platform/world grammar and a curated environment
registry. `environment/industrial_foundry_far.webp` is the only integrated generated raster:
1024×512, preloaded, presentation-only and selected by stable map ID. The JSON manifest is
tooling metadata; runtime uses `VisualAssetRegistry` and never executes profile/map paths.

player/ contains the independent animation state machine, detached visual frames, profile appearance adapter, opacity/outline Resource and modular M4/M23 robot parts. Presentation consumes copied state/events and cannot change gameplay. Fully illustrated module sheets and audio are deferred. See ../CHARACTER_PRESENTATION.md and `docs/ASSET_SPECIFICATION.md`.
