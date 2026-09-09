# Settings — M12 implementation inventory

Source: master specification sections 37–42 and schema 4. No gameplay timing changes.

| Category | Required values |
| --- | --- |
| Video | Resolution; Windowed / Fullscreen / Borderless; VSync; FPS 30, 60, 90, 120, 144, 165, 240, Unlimited (0) |
| Visual presets | Quality / Balanced / Performance (Steam Deck visual configurations, not device certification) |
| Presentation | Effects quality; screen shake Off / Low / Medium / High; post/camera effect intensity; speed effect intensity |
| Shared accessibility | High contrast; flash intensity; disable strong flashes; colorblind correction; text size; UI scale; HUD opacity 50–100% |
| Audio | Master / Music / SFX / UI / Ambience levels and mutes; empty menu/level music slots |
| Controls | Separate keyboard/mouse and gamepad profiles; all canonical actions; conflicts; cancel/reset; movement/dash/activity deadzones 0.05–0.9; prompt families Auto / Generic / Xbox / PlayStation / Nintendo / Steam Deck |
| Transactions | Saved / draft / applied; Apply / Cancel / defaults; write failure; display preview Keep / Revert / 15-second timeout / interruption |
| Framing | Fixed 1920×1080 competitive content, aspect-preserving bars on ultrawide and 16:10; UI remains inside that frame |

Schema 4 already constrains resolution dimensions to 320–16384, UI scale to 0.5–2,
continuous flash/shake to 0–1, and HUD alpha to 0.5–1. Preserve valid legacy values.
The specification does not prescribe preset coefficients, resolution choices, text-size
steps or colorblind correction algorithms. Concrete choices and validation evidence
will be documented here with the implementation.

## Concrete values and behavior

Resolution choices are window dimensions supported by the current desktop: 1280×720,
1280×800, 1600×900, 1920×1080, 2560×1080, 2560×1440, 3440×1440, 3840×2160,
plus the native desktop size when different. Unsupported choices are omitted; an existing
saved value remains visible and preserved. Native fullscreen/borderless use the desktop
resolution and disable the size selector. Exclusive fullscreen is requested for Fullscreen;
borderless requests Godot fullscreen. No OS monitor mode switch is implemented.

Window content always retains the 1920×1080 reference view with KEEP aspect. UI scale
changes font/control sizes inside that view, never camera zoom or world visibility.
Text size ranges 75–150%; UI scale 50–200%; all intensity sliders use 5% steps.
Legacy in-range values remain valid on reload. Screen shake choices are 0/0.25/0.5/1,
with a custom existing value also displayed. Shake is a bounded two-pixel camera offset
scaled by movement speed and setting; the follow model, map bounds and authority are unchanged.

| Preset | Canvas texture filter | Effect arc segments | Effect alpha | Effect line/arc AA |
| --- | --- | --- | --- | --- |
| Quality | Linear with mipmaps | 48 | 100% | On |
| Balanced | Linear | 32 | 75% | On |
| Performance | Linear | 16 | 50% | Off |

These are implementation choices, not numerical requirements from the specification.
Compatibility/OpenGL does not support 2D MSAA; no unsupported MSAA switch is exposed.
The preset does not override personal flash, shake, HUD, control or FPS preferences.
Speed intensity scales the max-speed trail. Flash intensity scales double-jump/respawn
rings; Disable strong flashes caps that contribution at 20%. Post intensity controls
a mild screen-edge vignette. High Contrast and Off/Protanopia/Deuteranopia/Tritanopia
correction apply a screen shader; correction is a channel-remapping aid with independent
shape cues retained. None of these options changes simulation or hazard telegraph timing.

Master/Music/SFX/UI/Ambience are real AudioServer buses. All child buses send to Master.
Levels range 0–100% and each bus has a separate mute; zero sets mute and a finite -80 dB
floor, avoiding negative infinity. UI buttons and player jump/dash/death use a quiet
procedural placeholder routed to UI/SFX. MenuMusic/LevelMusic nodes route to Music;
Ambience has an empty routed slot. Final sound/music production is outside M12.

## Transaction contract

Each page starts a detached draft. Apply commits all pending settings; Cancel/Back restores
the last successful Apply. Defaults changes the current category, including shared fields
shown on that page, and still requires Apply. Controls are previewed while editing so
prompts/capture remain current; their automatic persistence is suspended until Apply.
Bindings, options and deadzones have independent keyboard/gamepad profile storage.

A failed save restores the previous saved document and applied visuals, reports failure,
and retains the draft for retry. Cancel also restores the actual input map. Concurrent
profile/device/PB updates use the latest document; settings never reconstruct the profile.
Unknown fields are retained. Video/accessibility shared controls refer to one source.

Changing window mode or resolution captures the actual working native mode, flags, size
and position, applies provisionally and opens a 15-second exclusive Keep/Revert modal.
Revert is initially focused. Keep checks native readback then writes. Timeout, Back,
focus loss, close/teardown and failed native apply/write restore the prior window.
The preview is never serialized, so a killed process restarts with confirmed settings.
The current milestone has no online session or active online round in which settings
could be opened; future online UI must retain the specification's display-change lock.

## Verification and limitations

See docs/M12_VALIDATION.md for final evidence. Test stores are UUID-named OS-cache folders;
no test opens production user saves. A fake DisplayAdapter tests deterministic failures,
timeout and interruption. A separate native renderer test observes actual window size/mode,
VSync, modal input, UI boundaries and fixed competitive framing. Steam Deck presets are
visual configurations only; no Deck performance or Linux-driver certification is claimed.

Engine contracts: [Window 4.7](https://docs.godotengine.org/en/4.7/classes/class_window.html)
and [DisplayServer 4.7](https://docs.godotengine.org/en/4.7/classes/class_displayserver.html).
