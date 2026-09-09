# UI foundation — M11

F5 boots `core/bootstrap/main.tscn`. Bootstrap composes one SaveStore, InputLayer and
InputPreferences, then AppUI. AppUI extends the M10 TrialUI presentation adapter;
SoloTrial and its existing fixed-tick course/lifecycle/camera remain gameplay authority.

## Screens

Splash shows the wordmark and short fade, then advances after 1.2 seconds (or Continue).
An incomplete profile goes through language selection, nickname entry and Save/Continue.
Only a successful validated save sets onboarding_complete. Existing v3 users are asked
once; migration preserves their nickname, UUID, colors, settings and records.
Main Menu exposes its profile header, robot preview, New Game, Customization, Settings,
Level Editor and Quit confirmation. New Game contains Solo and an explicitly unavailable
Online page. Solo uses the existing TrialMapDefinition manifest and Training Circuit;
its schematic preview is illustrative, not a second source of gameplay metadata.
Settings provides Video, Audio, Controls and Accessibility through M12 transactions;
language remains in Profile. See SETTINGS.md.
Level Editor says In Development and has only Back. No editor or transport is included.

## Components and ownership

- IndustrialTheme builds one shared visual vocabulary: dark panels, mint structure,
  gold focus outlines, contrasting hover/pressed/disabled states and readable text.
- AppUI owns disposable panel trees and 200 ms presentation fades. Each reconstruction
  increments a generation, kills the previous tween, and rejects queued stale callbacks.
  Activation during a transition is consumed; gameplay input is cleared at boundaries.
  Map entry also waits for release of physically held gameplay controls before accepting input.
- Focus is wired across visible enabled controls, including the profile header and RGB
  sliders. Tab/Shift-Tab and shoulders traverse; sliders reserve Left/Right for values.
  Focusable content scrolls into view. Each screen remembers its last selected button.
- NameKeyboard is an exclusive Window with Latin/Cyrillic alphabets, case switching,
  digits, underscore, hyphen, space and delete. It edits its own text; Done updates only
  the parent draft. Back/Cancel discards it. Native keyboard entry remains available.
  Exclusive windows capture input and restore the invoking control on close.
- RobotPreview uses the actual M4 PlayerPlaceholder / RobotAppearance pipeline.
  It has no physics. RGB edits update it live. Saved colors are applied to the real
  course robot on entry and retry, without loading resources from cosmetic identifiers.
- ProfileEdit keeps a detached draft. Commit validates with PlayerProfileData, patches
  only nickname/body/accent/language in the latest document, then uses SaveStore.
  UUID/timestamps/device/preferences/PBs/unknown sections survive. Failure restores
  the prior in-memory document; UI stays on the form with a localized error.
  Language previews immediately and Cancel restores the persisted language.

## Navigation contract

Arrows/D-pad/left stick: focus. Enter/Space or bottom face: Confirm. Escape/right face:
Back. Tab/Shift-Tab or RB/LB: next/previous field. Automatic prompt family detection and
hotplug remain InputLayer responsibilities (Xbox/PlayStation/Nintendo/Steam Deck).
Device changes update the footer without reconstructing an in-progress profile form.
Gameplay actions remain separate from ui_* actions; no animated event controls physics.
Back during Solo toggles pause; the existing Retry/Map Select/Main Menu result loop stays.
Rebinding captures one input and can be canceled with Back. Disabled entries never focus.

The base canvas is 1920x1080, scaled with the existing aspect-preserving project setup.
Scrollable forms support smaller windows; the color controls use integer RGB channels
with no mouse-only popup. M12 provides configurable UI/text scale in bounded scrollable panels.

## Validation

Run `dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe` from the main project folder.
`tests/ui_foundation_test.gd` uses a unique OS-cache save directory and real Godot GUI
key/mouse/controller events. Add `-- --render-capture` for the normal renderer and PNGs
under ignored builds/. `dev_tools/time_trial_smoke.gd` drives the actual motor to Finish.
Synthetic gamepad events do not prove physical device/driver compatibility.
See docs/M11_VALIDATION.md and TESTING_CHECKLIST.md for review evidence and manual steps.
