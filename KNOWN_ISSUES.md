# Known issues

- M3 implements the controller in a standalone developer arena; F5/main and Windows staging still use the foundation placeholder. Run the arena with F6. Race modes, hazards, checkpoint/death scheduling, pause UI and final art are later work.
- Movement tuning is an initial baseline. Automated collision/replay checks do not replace subjective playtesting or prove cross-platform bitwise determinism. Final feel and physical-controller playtesting remain outstanding.
- The developer confirmed physical gamepad controls during M5 review. The subsequent shared movement/Dash layout needs a follow-up check; real USB/Bluetooth hotplug, other driver mappings and device-name detection remain separate validation items.
- Controller prompt family detection uses names and may need the explicit family override. Prompt descriptors are text/tokens; final glyph art is deferred.
- One InputLayer and one save writer are supported per application. Concurrent processes writing the same save are not coordinated.
- Recovery remains localized state for future UI. Same-directory rename plus flush is not a universal power-loss durability guarantee; unsupported saves stay read-only.
- Quarantined corrupt files and interrupted test-cache folders can remain for diagnosis.
- Linux export, Steam Deck hardware behavior and target-hardware performance are not validated. CI builds Windows staging with official templates.

- M4 uses procedural modular placeholder art. Unknown cosmetic slot IDs use the base modules; an asset registry, final art and production customization UI are future work.
- Opponent opacity/nickname support is a presentation framework tested using synthetic snapshots, not live multiplayer. Physical gamepad and subjective M4 pose review remain outstanding.

- M5 camera zones are authored axis-aligned world-space Resource rectangles. A map smaller than the visible frame is centered and necessarily exposes its backdrop. Camera collision, cinematics, shake and spectator switching are later work.
- Rendered jitter was measured on the local OpenGL setup; subjective follow/zone comfort and other hardware still need review. Small external teleports should emit relocated or explicitly reset the camera.
