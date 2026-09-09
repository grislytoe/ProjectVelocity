# Solo Time Trial — M10

F5 / `res://core/bootstrap/main.tscn` opens Main Menu → Solo → Map Select.
The short Training Circuit is a module demonstration, not the final 1–2 minute map.
Course: `res://gameplay/race/solo_course.tscn`, three owned modular sections,
two mandatory ordered checkpoints, spikes, moving/one-way/breakable platforms and a turret.
Platforms provide optional routes; shortcuts still pass both tall checkpoint volumes.

## Authority and timing

SoloTrial orchestrates HINT → COUNTDOWN → RUN → RESULT at physics priority -100.
M7 StartBarrier/ReadyStart authorizes GO; PlayerLifecycle alone authorizes checkpoints,
respawns and Finish. PlayerController/Motor remain the 60 Hz movement authority.
The hint blocks input and auto-dismisses after 180 ticks; Ready dismisses it early.
Countdown lasts 180 ticks. GO starts at elapsed tick zero before player movement.
Every subsequent running tick adds one; validated Finish captures that tick once.
Death and respawn do not stop time or invalidate an attempt. Pause freezes the entire
simulation and clock (including hint/countdown) and remains record eligible.
No render delta, wall clock, animation or second progress counter drives race timing.
Times and PB comparisons use integer 60 Hz ticks; display rounds once to milliseconds.
Timestamps can be equal within one physics tick. A total must be positive and at most 24 hours.
Live delta compares each checkpoint with the same checkpoint of the best complete run.
Result delta compares against the PB at attempt start, including on a new record.

## Restart, navigation and validity

R / top face held 30 ticks triggers once until release, including during death/respawn.
The existing rebindable `restart` action is dedicated to restart; the developer playground
retains its separate 60-tick policy. Rebinding is available in Main Menu → Controls.
Retry and Quick Restart skip the hint. Leaving and entering from Map Select shows it again.
Before physics, retry destroys/recreates the entire course: player, lifecycle, triggers,
platform phases, hazards, channels, pool, camera and barrier. Held movement/jump/Dash is
cleared; restart hold is preserved only to enforce the release latch. No deferred old shot
or old checkpoint callback survives. Finish retires the target pool immediately, then
freezes the course outside query flushing. Result buttons support mouse/keyboard/gamepad.

Force death emits gameplay_manipulated. External respawn/teleport through respawn_at
also invalidates; only the explicit lifecycle-authorized respawn path is exempt.
Future developer gameplay tools must emit that signal / call SoloTrial.invalidate before
mutation. Ordinary settings/input/presentation changes do not invalidate. No debug gameplay
buttons are exposed in Solo. This is local record eligibility, not an anti-tamper system.

## Records

See SAVE_FORMAT.md. New complete eligible runs save immediately. Equal/worse runs keep
PB total/timestamps, but can improve individual segment minima (including final segment).
Invalid/incomplete runs never write. Failed writes restore the previous in-memory save;
UI reports failure without claiming a new PB. The original SaveStore backup/recovery applies.

The map manifest has stable map ID, version, translation key, scene path and ordered IDs.
Its baked SHA-256 covers normalized gameplay .gd/.tscn/.tres content. The full validator
rejects a stale manifest; run dev_tools/check_trial_hash.ps1 -Update after intentional changes.
Baking keeps identity consistent between editor and exported compiled scripts. Records
from other UUIDs/map versions/content hashes remain stored but are not compared.
This conservative hash also changes after unrelated gameplay code edits. Future full
MapDefinition metadata/catalog and final map design remain outside M10.

## M11 integration

F5 now starts splash/onboarding, then Main Menu → New Game → Solo → Map Select.
The existing SoloTrial timing/PB/checkpoint/restart implementation and gameplay checksum
are unchanged. AppUI applies saved M4 body/emissive colors to the course on entry/retry.
Save schema v4 only adds an explicit onboarding marker; v3 trial_records are preserved.
