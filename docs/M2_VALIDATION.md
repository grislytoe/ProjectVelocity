# M2 validation evidence

Base: approved dev 0522580139e70ba3c2187c5f9a8e136692e507ff.
Branch: feature/m2-input-device. Engine: Godot 4.7.2 Stable.

Local validation:
- M0 bootstrap regression suite passed.
- M1 persistence suite passed: 139 checks, including sequential migration through the current schema.
- M2 input suite passed: 124 checks covering default maps, real Godot event dispatch, action edges, deadzones, eight-way selection, rebind/capture/reset, prompts, device switching, two-pad isolation, disconnect/reconnect and Godot hotplug signal routing.
- Persistence/reload of overrides and last device and schema v1→v2 migration passed.
- Full parser checks, editor import and headless boot passed.

Clean-cache validation passed all three suites. Real OpenGL Compatibility startup on AMD Radeon Graphics passed without errors/warnings; the 1280x720 screenshot was inspected and shows readable Jump/Dash prompts. Git whitespace checks passed. Windows staging CI results are linked in the M2 PR. Save schema is now 2; network protocol remains 1.

No physical controllers were connected (reported count: 0). Real USB/Bluetooth hotplug and controller-specific driver mappings could not be tested. No gameplay state, player movement, network/EOS/Steam integration, settings UI or rumble was implemented.
