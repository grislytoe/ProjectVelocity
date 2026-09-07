# Character presentation — M4

## Entry points

- `dev_tools/player_playground.tscn` (F6): play M3 mechanics with the M4 robot. Existing keyboard/gamepad input, one-second reset and held Dash aim behavior are preserved.
- `dev_tools/character_gallery.tscn` (F6): a developer pose sheet with local/opponent pairs, body/accent color pickers and an ability-ready toggle. It deliberately scrubs cosmetic poses, has no controller, and does not load or write a save. Technical pose names are diagnostic labels; interface strings support English/Russian.
- F5 and the Windows staging executable retain the foundation composition root. Developer scenes remain excluded from exports.

## One-way data flow

PlayerController publishes a detached PlayerVisualFrame after collision feedback and immediately on death/respawn/finish. The snapshot copies state, events, velocity, speed ratio, wall side, Dash vector and ability/invulnerability flags. It holds no motor, controller, input service or network reference. The optional presentation child consumes these values; deleting the child leaves physics unchanged.

PlayerAnimationMachine accepts only PlayerVisualFrame, selects a cosmetic pose and advances cosmetic timers. PlayerPlaceholder (retained class name for scene compatibility) poses RobotPart nodes and draws effects. No animation completion callback, pose, playback speed or art parameter gates movement, collision, ability availability or lifecycle timing. The entire 720-tick collision replay has the same hash with the presentation child removed.

Future remote adapters may reconstruct visual frames from validated gameplay snapshots/events. M4 contains no transport, replication, network authority or opponents with simulated gameplay. Dash preselection is a separate local argument and is never a field of PlayerVisualFrame.

## Robot modules and artwork

The base is a clean, beveled vector android approximately 64px tall at the 1080px reference viewport. Head, torso, left/right arms and left/right legs are independent RobotPart nodes under Modules. A hidden Hat attachment reserves the fifth profile slot category. Rotation and translation articulate rigid panels; scale stays (1, 1), with no squash/stretch. Antialiased contours, visor and panel lights remain editable without generated bitmap dependencies.

Profile slot IDs are copied as metadata, never treated as paths or executed. Unknown/future IDs render the base modules. A future curated asset registry can replace named modules for head/hat/torso/arms/legs. Final art, a wardrobe UI and cosmetic unlock logic are outside M4.

## Pose mapping

| Gameplay state/event | Cosmetic pose and placeholder treatment |
| --- | --- |
| Idle | Idle: light arm sway |
| Run | Run: opposing limb cadence proportional to horizontal speed; subtle max-speed trail |
| Jump | Jump: raised arms and tucked legs |
| Fall | Fall: open arms and descending legs |
| Extra-jump event | DoubleJump: rigid-body rotation and expanding accent ring for 11 ticks |
| WallSlide | WallSlide: lean mirrors the contacted wall |
| WallJump/state or event | WallJump: outward lean and separated legs |
| Dash | Dash: one base pose rotated into eight directions with an accent streak |
| Landed event | Landing: bent/translated limbs for six ticks; no scaling |
| Death | Death: modules disperse and fade over 27 ticks (0.45s); no respawn authority |
| Respawn | Respawn: rebuild modules and a 15-tick cosmetic pose; invulnerability halo follows the snapshot |
| Finish | FinishVictory: arms raised |
| High-speed reversal | Skid (five ticks) → Turnaround (four ticks) → Run |

Death/Finish/Dash override temporary poses. Jump, wall contact and landing interrupt stale transitions. The one-tick gameplay Respawn can remain visible cosmetically while simulation resumes. FastFall is reserved in the pose enum, without a gameplay transition. Timed poses cannot delay a jump, Dash or respawn.

## Color customization pipeline

Use `visual.apply_profile(profile)` with a validated PlayerProfileData, including profiles reconstructed by the existing save layer. RobotAppearance validates/copies body RGB, accent RGB, nickname and cosmetic slot values. Invalid profiles return false and leave the previous appearance intact. The source profile is never mutated. Profile alpha is deliberately normalized to 1 for rendering so saved colors cannot make a competitor invisible; identity is never inferred from nickname.

Body/accent colors reach every RobotPart; readiness dims emissive markers without substituting the selected body color. Known-good profile data remains owned by M1. The playground accepts an optional injected `profile` before entering the tree; otherwise it uses default materials. The gallery exercises the same apply_profile pipeline with an in-memory profile. No settings menu or production save writer is added.

## Opacity, outlines and readiness

CharacterPresentationConfig (`visuals/player/default_presentation.tres`) owns cosmetic tuning. Local root alpha is 1.0; opponent root alpha defaults to 0.3. Parts, VFX and the opponent nickname inherit this once, preserving selected RGB values and avoiding accidental 0.09 opacity. `is_local` switches the policy at runtime, suppresses local nickname and discards opponent preselection. The local outline defaults to 1.2px; the opponent outline is absent by default. Call refresh_style after changing a presentation config at runtime.

Head/arm/torso lights encode Dash readiness; leg lights encode extra-jump readiness. Filled circle/square markers mean ready; hollow markers mean unavailable, providing a shape distinction independent of hue. Replenishment restores lights. Effect intensity is a presentation-only Resource setting; no strong full-screen flashes are used. An invulnerability halo replaces body-opacity blinking.

The local-only Dash arrow shows selected aim and dims when unavailable. Successful Dash, Death, Respawn and Finish hide it. Opponent mode ignores selection even if supplied accidentally. InputLayer owns successful activation clearing and can reuse held aim on the next fresh trigger; animation does not own that rule.

## Validation and limits

Run `dev_tools/validate.ps1`: all M0–M3 regressions, M4 transition/material/policy checks, parser/import checks and equal replays with/without presentation. `godot --path . --script dev_tools/character_gallery_smoke.gd` captures the actual normal-renderer gallery; `dev_tools/player_presentation_smoke.gd` captures the playable arena. Logs/screenshots are ignored under builds/validation.

Version 0.4.0-dev / build 5. Save schema stays 2; network protocol stays 1. Physical gamepad, Linux/Steam Deck rendering, final art and subjective animation feel still require later review. Opacity/nickname support is a visual framework, not implemented multiplayer.
