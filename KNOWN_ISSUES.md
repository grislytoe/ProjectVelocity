# Known issues

- M12 fullscreen and borderless use the desktop resolution; windowed resolution is
  selectable. No OS monitor-resolution switching is attempted. Unsupported saved modes
  are reported and retain the engine's working startup window.
- M12 native runtime was exercised on Windows/OpenGL AMD graphics at a 1920×1200
  desktop, including a 1680×720 ultrawide window. A physical ultrawide monitor, Steam
  Deck, Linux/Wayland and physical controller hotplug remain hardware review items.
- Compatibility rendering does not support 2D MSAA. Visual presets use supported texture
  filtering and procedural effect detail/antialiasing; they are not hardware benchmarks.
- Colorblind correction is an optional channel-remapping aid; independent shape cues
  remain. Final audio assets are absent; quiet UI/SFX placeholders and routed empty
  music/ambience slots are intentional for this milestone.

- F5/main and staging provide Solo Time Trial on the short Training Circuit. Final map/art and online modes remain future work. M7 lifecycle and all 22 developer playground stations remain available with F6.
- Movement tuning is an initial baseline. Automated collision/replay checks do not replace subjective playtesting or prove cross-platform bitwise determinism. Further tuning and platform coverage remain open; the developer accepted keyboard and gamepad movement during earlier milestone reviews.
- The developer confirmed physical gamepad controls during M5 review. The subsequent shared movement/Dash layout needs a follow-up check; real USB/Bluetooth hotplug, other driver mappings and device-name detection remain separate validation items.
- Controller prompt family detection uses names and may need the explicit family override. Prompt descriptors are text/tokens; final glyph art is deferred.
- One InputLayer and one save writer are supported per application. Concurrent processes writing the same save are not coordinated.
- Recovery remains localized state for future UI. Same-directory rename plus flush is not a universal power-loss durability guarantee; unsupported saves stay read-only.
- Quarantined corrupt files and interrupted test-cache folders can remain for diagnosis.
- Linux export, Steam Deck hardware behavior and target-hardware performance are not validated. CI builds Windows staging with official templates.

- M4 uses procedural modular placeholder art. Unknown cosmetic slot IDs use the base modules; an asset registry and final art remain future work; M11 supplies RGB customization.
- Opponent opacity/nickname support is a presentation framework tested using synthetic snapshots, not live multiplayer. The developer accepted the placeholder presentation; replacement art is planned later.

- M5 camera zones are authored axis-aligned world-space Resource rectangles. A map smaller than the visible frame is centered and necessarily exposes its backdrop. Camera collision, cinematics and spectator switching are later work; M12 adds optional bounded shake.
- Rendered jitter was measured on the local OpenGL setup; the developer accepted follow/zone comfort after the 30% zoom reduction. Other hardware still needs review. Small external teleports should emit relocated or explicitly reset the camera.

- Developer fixtures remain offline. New station usability and physical D-pad navigation require manual review. M9 hazards now have isolated stations; network synchronization remains future work and the long lane is geometry for later reuse. Development scenes are intentionally absent from the Windows staging build.

- M7 respawn validation deliberately requires static support; moving geometry must use an appropriate physics body rather than animating StaticBody2D. If Start and checkpoint are both blocked, recovery waits safely and displays a message. Production map-wide authoring validation and actual online transport are not implemented.

- M8 platform routes are local fixed-tick simulation; no synchronized online clock/state replication yet.
- Pad flight resumes ordinary M3 variable-height gravity/air control after the impulse. Final feel and physical-controller review remain manual.
- Moving platforms carry riders but do not implement crushing damage. Authors must leave player clearance along routes.
- Platform art is procedural placeholder geometry; final art and an editor UI are deferred. Temporary restore clearance uses a conservative convex hull.

- M9 uses procedural hazard/telegraph art and offline authority, with two explicitly registered
  player IDs. The second playground actor is neutral-input, not a network peer or physical
  input owner. Production map, host replication and synchronized clocks are later milestones.
- Turret engagement contention uses stable scene processing order; no fairness scheduler is
  implemented. Cooldown releases slots. The warning direction is locked for evasion.
- M9 timing/lead/cadence and warning readability still require the user's gameplay review.
  The caps station deliberately overrides round speed/cadence to make saturation visible.
- Author hazards at unit scale and place spawn anchors outside moving-saw routes. Area-based
  fatal hazards use fixed-tick overlaps; projectile collision uses swept circles. Inactive
  spike/laser volumes are conservatively excluded from respawn even while harmless.

## M10 status

F5/Main and staging now offer the complete Solo loop; the earlier foundation-only note
is superseded. Training Circuit is deliberately short and procedural; it is not the final
map/art milestone. Keyboard pilot proves reachability, not subjective difficulty/feel.
Physical gamepad navigation, Linux/Steam Deck and low-end performance remain manual.
Local records are not cryptographically authenticated. Future debug mutation entry points
must use the explicit invalidation contract. No online mode or transport was added in M10. M11 now supplies the front end.

## M11 limitations

The first front end is now available; earlier notes deferring all customization UI are
superseded. Robot art remains the approved modular M4 placeholder, ready for later art.
Only Training Circuit is playable. Online and production Level Editor are unavailable.
M12 now provides Video/Audio/Controls/Accessibility settings; see SETTINGS.md.
Physical controller/driver, Linux and Steam Deck validation remain manual. Automated
controller events exercise Godot UI navigation only. On-screen keyboard supports the
allowed alphabets and case; it is local, with no Steam Input dependency.
