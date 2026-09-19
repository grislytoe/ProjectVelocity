# M19 validation — BLOCKED live gate

Main folder `C:/Godot Projects/ProjectVelocity`, Windows, exact
Godot4.7.2.stable.official.ed1daf0bf. Build0.19.0-dev/25, protocol3/wire2, save5.
All artifacts referenced below are ignored local evidence; no real credentials or SDK
callbacks were supplied. Final PR/head CI is checked and linked in delivery separately.

## Non-live evidence

`tests/eos_adapter_test.gd` passed with
`PROJECTVELOCITY_M19_POLICY_OK live=false native=false`, exit0. Log:
`builds/validation/m19-unit-final.stdout.log` (stderr empty). Covers:

- ASCII alphabet/length/case/edge trimming, Unicode homoglyph rejection, secure random format,
  deterministic test entropy, rejection tail, collision retry/exhaustion/service failure.
- Identity sequence, opt-in/config/boundary absence, Auth versus Connect, continuance without
  automatic linking, cancellation/stale callback, logout, timeout and terminal shutdown.
- Exact metadata types/compatibility, full/owner-absent/closed rooms, zero/one/multiple/duplicate
  results, truncated search, capacity race, publication acknowledgement, cancellation and timeout.
- Fake authenticated datagrams through the existing codec: request membership, socket/epoch,
  malformed/oversize/channel/reliability rejection, control/data classes, receive work cap,
  outgoing backpressure, close and stale packet after a new composition.
- Ordinary process has no IEOS singleton; native open remains unavailable.

These tests do not exercise a platform, EOS callbacks, service-side arbitration, EOSG native
packet parser or an Internet connection. Fixture names are deliberately synthetic, not PUIDs.
Initial test caught an alphabet-count mismatch (32 symbols versus the intended31); exclusion
of L was made explicit and the test repeated successfully. No failed test is counted as PASS.

## Regression and presentation

Full local `dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe` passed: log
`builds/validation/m19-full.log` ends with `M0-M17 validation passed`, including import,
all GDScript parsers, legacy tests, ordinary boot, M19 policy, separate-process ENet and
mandatory M17 stress matrix. Final focused M19 policy rerun also passed after the added
Unicode/native-absence/lifecycle assertions. Existing validator success marker remains
M0-M17 for tooling compatibility; M19 adds its own mandatory policy marker.

Normal OpenGL Compatibility/AMD renderer GUI run passed `PROJECTVELOCITY_M11_OK` with empty
stderr (`builds/validation/m19-ui.*.log`). Both1920x1080 RU/EN Online screenshots were inspected:
readable localized unavailable message, disabled Create/Join, Back focus ring, no overlap
or identity/secret content. These are unavailable-state captures, not live lobby screens.
Prerequisite recheck at resumption still reports all nine names and both template sets absent.

M18 native20+3 and launcher failure checks remain separate Windows/Linux CI jobs. No local
EOS-bearing export is attempted without templates/full package review. No modified vendor binary
or full addon is installed. Ordinary Windows Staging/exported ENet is covered by existing PR CI.

## CI evidence and infrastructure blocker

On code commit `49a2765ef18a83fc24f8473b11b58736b6ceece5`, native PR run
[35457018993](https://github.com/grislytoe/ProjectVelocity/actions/runs/35457018993)
completed all cold-import/M19 policy/M18 native20+3/launcher-cleanup checks on both Windows
and Ubuntu24.04. Both jobs then **failed** at Upload sanitized text evidence:
GitHub reported its artifact storage quota was exhausted. Overall workflow is FAILURE,
not a green CI claim. No tests were bypassed and upload failure was not suppressed.
No historical artifacts were deleted. Repository administration must review storage/retention
and restore artifact availability, then rerun the failed workflows on the intended review SHA.
GitHub reports usage recalculation can take6–12h; a blind immediate rerun is not a fix.
Full Windows validator/export workflow status and final head are checked separately at delivery.
The additional rendered13-case M17 run writes `builds/validation/m19-extended.log`;
its completed result is reported at delivery, separately from the already-passed mandatory matrix.

## Reproduce

```powershell
./dev_tools/check_eos_prerequisites.ps1
./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe
# Godot GUI executable can return asynchronously in a shell; use Start-Process -Wait
# or the repository validator for reliable exit-code and stdout/stderr checking.
```

Rendered existing GUI harness: launch Godot with `--path . --script tests/ui_foundation_test.gd
-- --render-capture --capture-tag=m19`, through Start-Process with a120s owned-process timeout.
Captures under `builds/m11-online-{en,ru}-m19.png` show unavailable, not live Create/Join.
No live controller code-entry or physical-controller result is implied by simulated GUI actions.

Current blocker details: [M19 report](M19_BLOCKERS.md). Secure environment/review plan and
missing live-executor boundary: [M19 integration](M19_EOS_INTEGRATION.md). No claim that
native-only loading, mocks, editor sessions or ENet satisfy standalone Internet acceptance.
