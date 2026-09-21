# M21 Online Match / Series — validation and acceptance split

Workspace `C:/Godot Projects/ProjectVelocity`, branch `feature/m21-online-match-series`.
Base `origin/dev` `92c37319471fdd68dc06e066206521845ec70c34` (M20 PR#21 merge).
Build **0.21.0-dev /27**, protocol **4 /wire3**, save schema **5**. Protocol/wire bump is
required by incompatible WELCOME/READY/INPUT/RaceBaseline semantics and the new LOADED/action
packets. No save migration is required. Smooth spectator targeting changes the conservative
shared code identity: Training v6/checksum `d46d87e0…`, Industrial v5/checksum `241bfd1d…`;
historical PB rows remain stored separately. User-owned `project.godot` remains
byte-identical and excluded: SHA256
`5B9713ACA5045DD697EA09DF21E9DE658283B782B3B0C8F2CC540539FABB65AC`.

## Acceptance decisions

- **M21 transport-independent lifecycle + local two-client series: PASS** on the tests and
  standalone loopback ENet evidence below. ENet is only the injected development adapter.
- **Live EOS two-client Internet acceptance: BLOCKED.** M19 still lacks configured production
  platform/Auth/Connect, native Lobby/P2P executor, authorized identities, full licensed SDK/
  exports, authenticated sender proof and an Internet session. Production Online continues to
  show localized unavailable state. No editor, fixture, screenshot or loopback run changes this.

## Delivered authority contract

`OnlineSeries` is the only series state owner and `NetworkSession` remains the only simulation
owner. Explicit phases cover preparation, synchronized loading, controls hint, countdown,
racing, Finish window, round results, both-Ready, final results, reconnect, lobby and ended.
Host-only transitions use fixed service/match ticks; UI intents never write results.

Both clients must confirm the exact MapDefinition ID/version/checksum with current series and
round generation. Wrong/stale/future/duplicate acknowledgements are rejected. Host begins the
InputLayer-derived controls hint only after both confirmations, publishes one start tick and
releases StartBarrier/race clock at that tick. Input adds series/round generation; late prior-
round commands cannot enter the new world.

The first M7-validated Finish records the winner, blocks that actor and sets exactly1800 ticks.
The second Finish is valid through the deadline tick; afterward it is DNF. Immutable results
contain participant IDs, settings identity, round/generation, winner, valid times/status,
progress and ordered checkpoint evidence. Score increments once. Even final score is Draw with
no tiebreaker. Winner camera switching is presentation-only and restores safely on transition.

Results advance to both-Ready. Host then atomically retires pools, restores dynamics, clears
progress/events/prediction/interpolation/commands, respawns actors, bumps generations and
returns to synchronized loading. Play Again bumps series generation and clears all history;
Return Lobby retains membership/settings; Main Menu ends cleanly. M16's45-second guest pause,
safe checkpoint resume and once-only host forfeit award remain; host loss ends without migration.

## Automated coverage

- `online_series_test.gd` at fixed30/60/144: load identity/generation, shared tick, Finish and
  exact deadline boundaries, DNF/evidence, Ready revisions, full reset, one/two-round winner/
  Draw, best times, Play Again/Lobby/Menu, disconnect award and50 repeated lifecycle cleanups.
- `network_race_test.gd`: real Industrial M7/M8/M9 world, mandatory checkpoint enforcement,
  forged/duplicate host-state rejection, protocol3 rejection, spectator target/fallback and
  presentation-only actor invariance, retry/reconnect and pool teardown.
- `online_match_ui_test.gd`: RU/EN result/Draw/DNF rendering, focusable result actions,
  keyboard/controller prompt abstraction and Lobby/Menu routes without persistent saves.
- Full validator discovers/parses all scripts, retains every M0–M20 suite, runs M15/M16 process
  regressions, M17 stress and the complete M21 standalone series. All fixture save/log roots are
  unique under ignored `builds/validation`.

## Two-process standalone evidence

Godot4.7.2 stable, Windows, normal OpenGL Compatibility, two independent OS processes,
physics60/snapshots20, Industrial Foundry, clean loopback ENet. Reproducible command:

```powershell
./dev_tools/test_local_network.ps1 -Godot C:/Godot/Godot.exe -Race -Retry -Series \
  -Map industrial -Rendered -Resolution 1280x800 -Port 24937
```

Final rendered PASS folder (ignored local evidence; Industrial v5 with the final checksum):
`builds/validation/m15-clean-20-60-d93ca212f993423bb0da9a0a67f81baa`.
Both endpoints converged with zero wire rejection to two results, score1–1 and Draw. Round1:
guest first at195 ticks, host second at365. Round2: host first at195, guest remained unfinished;
the result appeared at authoritative clock2360, exactly deadline2360, with statuses
`FINISHED/DNF` and reason `SECOND_PLAYER_TIMEOUT`. All21 completed checkpoints/3 Finish/
2 winner/2 start event counts matched; final pools/history/interpolation were empty/bounded.
Host/client final screenshots were inspected at1280×800; localized result history, DNF, Draw,
best times and all three actions are readable. This is localhost evidence, not Internet/WAN.

The final headless full-validator series independently passed in
`builds/validation/m15-clean-20-60-b604630c2923427988c3f81695825092` with the same score,
history, DNF boundary and endpoint convergence.

## Final local matrix

- `dev_tools/validate.ps1`: PASS through the final marker `M0-M21 validation passed, including
  complete separate-process localhost series`; retained log
  `builds/validation/m21-full-delivery-final.log`.
- Clean separate processes: PASS at30/60/144 render caps. WAN/stress/combined loss, jitter,
  duplication, reorder and reconnect profiles: PASS. Active-race reconnect emitted RESUME;
  post-final reconnect restored the immutable final result instead of resuming gameplay.
- Malicious authoritative-state/input checks: PASS at RTT80/150/200/250. Evidence folders:
  `m15-rtt80-20-60-418154056e9a4403858522f050bcaeed`,
  `m15-rtt150-20-60-fa06e21f875d48b593d78443e3f541e1`,
  `m15-rtt200-20-60-26bcb1af9dda424cbe335c7585be8983`, and
  `m15-rtt250-20-60-e8f46473d2654ba0b7648da0821ca576`; all completed with zero
  wire rejection and matching durable results.
- Normal renderer: rendered two-process series PASS at1280×800 and UI scene PASS at1920×1080
  under OpenGL Compatibility, with no script error or warning (`m21-ui-1920.*.log`).
- `git diff --check` and the exact final commit/CI results are recorded at delivery.

## Remaining validation and delivery

CI must separately report test/export job status and artifact upload status. GitHub's previously
observed artifact-quota failure is an external upload failure, never a test failure or hidden
success; do not delete artifacts without explicit authorization. Final commit, PR URL and exact
CI run are reported at delivery.

No physical WAN/Linux/SteamOS/physical-controller certification, host migration, persistent
reconnect credential or native EOS success is claimed. Do not merge automatically or start M22.
