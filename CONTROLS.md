# Input and device layer — M2

## M15 developer Local Network

Launch `res://networking/local_network.tscn` with `--role=host` or `--role=client` after
Godot's `--` separator; see NETWORKING.md for complete commands. WASD/left stick movement
and Dash direction, Space/A Jump, fresh Shift/RB Dash. F8 disconnects. Guest F9 retries
the same session within 45 seconds. Close windows to leave. This developer scene uses
default bindings without touching saved preferences. Solo R Quick Restart/pause remain
offline-only; networking never creates Time Trial records.


## M12 settings controls (current)

Main Menu → Settings provides all four pages. Controls explicitly selects Keyboard/mouse
or Gamepad independently of the active device. All canonical movement, action and UI
bindings can be changed; shared movement/Dash aim remains one binding. Capture accepts
one key/button/axis and reports conflicts. Back cancels capture; Reset this profile
affects only the selected profile. Defaults resets both profiles and input options.
Movement/Dash/activity deadzones and Auto/Generic/Xbox/PlayStation/Nintendo/Steam Deck
prompt families are available. Existing multi-binding saves remain readable.

Bindings preview while editing; Apply persists and Cancel restores the last saved input
configuration. Automatic device persistence cannot save draft bindings. Back from any
settings page discards changes since the last Apply. Sliders use Left/Right, lists use
Confirm then directions, and Tab/shoulders traverse focus. The display modal defaults
to Revert and accepts all three input families, including remapped ui_cancel/accept.
Gameplay entry continues to require fresh input after leaving UI. No rumble/Steam Input.

InputLayer is the application-wide Godot Input adapter, created by bootstrap. Gameplay consumes sample() → InputFrame; it does not query keyboards, controller IDs or platform SDKs directly. No movement, ability state or player state machine exists in M2.

## Defaults

| Action | Keyboard | Standard gamepad |
| --- | --- | --- |
| Movement | WASD | Left stick |
| Dash selection | WASD (same bindings as movement) | Left stick (same bindings as movement) |
| Jump | Space | Bottom face button (Xbox/Deck A, PlayStation cross, Nintendo B) |
| Dash trigger | Shift | RB / R1 / R |
| Pause intent | Escape | Start / Options / + |
| Quick restart hold intent | R | Top face button (Y / triangle / X) |
| UI directions | Arrows | D-pad or left stick |
| UI accept | Enter or Space | Bottom face button |
| UI cancel | Escape | Right face button |
| Focus next / previous | Tab / Shift+Tab | Right / left shoulder |

Jump/pause/restart defaults are initial M2 choices; all are rebindable. The developer arena requires a continuous one-second restart hold; pause UI is not implemented. Stick axes and face positions use Godot's standard mapping; no Steam Input dependency or rumble.

## Profiles and bindings

Keyboard/mouse and gamepad overrides are independent. InputBindings contains source-controlled defaults for every action. The stored profiles contain only overrides; empty overrides use defaults. Up to four bindings per action are supported. Empty arrays explicitly unbind an action except ui_accept/ui_cancel, which retain at least one binding.

Tokens:
- key:PHYSICAL_CODE:MODIFIERS, with mask Shift=1, Ctrl=2, Alt=4.
- mouse:BUTTON (1–9), keyboard profile only.
- button:INDEX or axis:INDEX:SIGN, gamepad only; axis 0–5 and sign -1/+1.

API: rebind(profile, action, tokens) validates token type and rejects conflicts within gameplay or UI contexts, returning ok/message_key/action. Gameplay and UI may share a binding. begin_rebind()/cancel_rebind() provide event capture without building a settings UI; capture takes the first pressed key/button or axis beyond 0.6, suppresses gameplay intent and consumes the captured input. Modifier-only bindings are supported; full modifier masks can also be assigned directly through rebind(). reset_profile() restores defaults. Rebinding clears held state and refreshes prompts.

Configuration is copied on configure()/rebind(). Treat exposed dictionaries as read-only; edit through the API. One InputLayer owns the application's input maps at a time. Keyboard entries use pv_keyboard_ACTION, pad entries pv_pad_ID_ACTION. Standard ui_* maps drive Godot Control navigation; prior UI mappings are restored when the layer exits.

## Vectors and Dash

Movement and Dash read the same movement controls and use configurable radial deadzones (defaults 0.2 and 0.25); outside the deadzone magnitude is rescaled to 0–1 and diagonal movement is clamped. Activity detection has a separate default threshold 0.3. Options accept finite thresholds 0.05–0.9.

Dash direction quantizes to exactly eight unit vectors, with neutral = zero. Sectors are centered every 45 degrees; midpoint ties advance to the next sector. Selection persists after releasing a direction. Dash trigger is an independent pressed edge and never fires from direction input alone. The gameplay consumer calls clear_dash_selection() after accepted Dash, death or respawn. After clearing, the next Dash pressed edge can reuse a continuously held keyboard/stick direction. Holding direction or the trigger alone does not auto-fire or queue a Dash on ability refresh. A new/changed direction still updates preselection without a trigger. Ability availability is never stored here.

Call sample() once per physics tick and distribute that snapshot. Edges use Godot's just-pressed/released semantics. InputFrame contains movement, selected Dash direction, jump pressed/held/released, Dash/pause pressed, and restart held. It contains no network identity, physics state or ability cooldowns.

## Device detection, hotplug and prompts

Last meaningful device wins for gameplay sampling. Key/button presses, mouse movement >=2 pixels, and stick activity above the threshold switch device; key echo, releases and drift do not. Each connected pad has separate action maps, so an inactive pad cannot supply another pad's movement. The most recently used pad becomes active.

Input.joy_connection_changed updates maps. Connecting alone does not steal focus. Disconnecting the active pad falls back to keyboard/mouse and clears held actions and Dash selection. Rebuilds and application focus loss also clear transient state; focus loss cancels capture.

InputPrompts returns token/label descriptors independently of UI assets. Families: generic, Xbox, PlayStation, Nintendo, Steam Deck. Auto-detection uses the Godot device name; set_options() provides a manual override for ambiguous names. Generic/extra buttons use localized numeric fallback labels. Bootstrap displays only Jump/Dash hints to demonstrate device/rebind switching. This is not a settings menu or glyph asset system.

InputPreferences persists profiles, deadzones, prompt family and last active device through SaveStore after 0.5 seconds of inactivity, or flush() on shutdown. No per-frame writes occur. Unsupported/read-only saves are not overwritten. Language changes refresh the hint.

## Validation

tests/input_layer_test.gd sends synthetic InputEvents through Godot Input, tests vectors/edges, bindings, prompts, two-pad isolation, hotplug adapter and Godot signal routing, focus cleanup, persistence and v1→v2 migration. It uses isolated save paths.

The developer confirmed physical gamepad controls work during M5 review, before the shared movement/Dash layout change. The new layout still needs a brief manual check. USB/Bluetooth hotplug, platform-specific naming and other target devices remain separate hardware checks; synthetic tests do not claim that coverage.

## Approved shared-aim control update

The developer requested movement-bound Dash aim during M5 review, superseding the original separate arrows/right-stick layout. Rebinding move_left/right/up/down updates both movement and Dash aim. Legacy dash_left/right/up/down API names resolve to movement bindings for reads, prompts and rebinding. Old independent direction overrides remain valid in schema 2 and are preserved but ignored at runtime; no save migration or real-user save rewrite is needed. Arrows still navigate UI; the right stick does not select Dash. Shift/RB remain fresh-edge triggers, with no automatic activation on refresh.

## M10 Solo

F5 → Solo → Training Circuit. Ready dismisses the 3-second controls hint early.
Escape / Start pauses the simulation; Resume continues without invalidating records.
Hold R / top face for **0.5 seconds** once per release to Quick Restart, even while dead.
Solo restarts go directly to countdown. Playground R/top face stays **1 second**.
Main Menu → Controls rebinds Jump, Dash, Restart and Pause for the active device;
conflicting bindings are rejected. Hints follow the last active keyboard/gamepad device.
Movement/Dash aiming and fresh Shift/RB triggering are unchanged.

## M11 UI navigation

F5: splash → language/nickname on first run → Main Menu. Open the profile header to
edit nickname/language; Customization changes body/emissive RGB. Native text input or
exclusive on-screen Latin/Cyrillic keyboard supports the complete controller path.
Arrows/D-pad/left stick navigate; Enter/Space/bottom face confirms; Escape/right face
returns or cancels. Tab/Shift-Tab and RB/LB traverse fields; Left/Right adjusts RGB.
Quit opens a modal with Cancel initially focused. Device changes keep current drafts.
Main Menu → New Game → Solo → Training Circuit preserves the M10 run controls.
Main Menu → Settings → Controls retains rebinding (Back cancels input capture).
Solo Escape/Start pauses, freezing simulation/time without invalidation; Quick Restart
still holds R/top face 0.5 seconds once until release. Developer reset stays one second.
