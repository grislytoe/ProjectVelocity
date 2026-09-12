# M17 validation and manual review

Main folder only; branch `feature/m17-network-stress-tools`, approved dev base
`2d11206f43534a84025d3e476b44328f6be7a6d0`, base CI run34684846563 successful.
Build **0.17.0-dev /23**, protocol **3 /wire2**, save schema **5**.
project.godot remains byte-identical SHA256
`5B9713ACA5045DD697EA09DF21E9DE658283B782B3B0C8F2CC540539FABB65AC`, excluded from commit.
Training/Industrial checksums, physics60, shared motor and projectile tuning unchanged.

## Measured Windows / real ENet evidence

Godot4.7.2.stable.official.ed1daf0bf, OpenGL Compatibility/AMD Radeon Graphics.
Two independent localhost processes, host seed15/client29, physics60. Both endpoints apply
the stated one-way delay INBOUND once. Rates in the table are simulated EXTRA RTT, not
promised measured RTT. Monotonic send-to-first-PONG RTT includes transport/poll/OS time.
Quality labels use measured RTT; the master never specifies RTT/one-way or numeric comfort
thresholds. Combined settings:75ms one-way,uniform ±25ms jitter,in/out loss5%/2%,
duplication3%,reorder15% adding66.667ms. No bandwidth shaping.

| Case | Sim one-way/RTT ms | Snapshots/FPS | RTT p50 H/C ms | Ordinary / moving error p95 C px | Queue peak H/C; history C | Functional |
|---|---:|---:|---:|---:|---:|---|
| clean | 0.0/0.0 | 20/60 | 66.6/33.5 | 0.00/2.56 | 19/3; 9 | PASS |
| 80 | 40.0/80.0 | 20/60 | 113.5/115.7 | 0.05/27.01 | 22/4; 13 | PASS |
| 150 | 75.0/150.0 | 20/60 | 167.2/169.9 | 0.05/51.75 | 24/5; 18 | PASS |
| 200 | 100.0/200.0 | 20/60 | 246.8/232.1 | 10.22/109.25 | 26/5; 20 | PASS |
| 250 | 125.0/250.0 | 20/60 | 283.7/281.8 | 14.06/103.50 | 28/6; 24 | PASS |
| combined running reconnect | 75.0/150.0 | 30/60 | 183.4/182.4 | 30.67/111.20 | 12/7; 18 | PASS |
| 200 Results reconnect | 100.0/200.0 | 20/60 | 233.2/220.8 | 24.92/109.25 | 10/5; 18 | PASS |
| 250 render30 | 125.0/250.0 | 20/30 | 276.0/268.6 | 23.00/103.50 | 37/9; 25 | PASS |
| 150 render144 | 75.0/150.0 | 20/144 | 167.6/175.9 | 11.50/44.72 | 29/6; 78 | PASS |
| combined repeat | 75.0/150.0 | 30/60 | 183.1/184.2 | 19.81/95.23 | 11/7; 17 | PASS |
| profile switches | 0.0/0.0 | 20/60 | 16.8/16.8 | 0.01/0.01 | 12/4; 19 | PASS |
| host drop | 125.0/250.0 | 20/60 | 266.8/267.9 | 53.00/53.00 | 11/5; 20 | PASS |

Race cases run host2400/client2280 service ticks (40s/38s plus scheduling); ordinary
profile-switch/host-drop cases1200/1080 ticks (20s/18s). Each pair has a shared90s race or45s
ordinary hard deadline. Guest reconnect at700 (running) or1900 (Results), reopen after45ticks.
Host drop at900. Profile switches on both endpoints: rtt250 at800, clean at1000; exactly2
successful changes asserted. Rendered boundary cases use1280x800 windows, render30/144 cases
1920x1080. Simulated RTT can measure in a higher band due to process/poll overhead.

All ten race cases reached both Finish, winner2, progress7/7, identical critical event
counts and zero final paired clock skew. The comparison asserts actual checkpoint/death/
Finish/winner/saw/laser/projectile events, early/skipped Finish rejection, Jump Pad, breakable
restore, turret fire/hit and pool return. Malicious cases sent hundreds of fabricated critical
snapshots and exercised host rejection. No client claim grants progress, death, Finish or hits.
Both endpoints clean queues, prediction history, interpolation, events and active pool slots
to zero at teardown. Pool nodes remain preallocated10 until course destruction; M16 repeated
scene tests cover node/signal disposal. Overflow rebases remained zero in these runs.

Ordinary p95 is last300 eligible reconciliations, so a largely stationary late-race fixture
can have a small p95. Moving p95 is the separate speed>1px/s subset, not a latency guarantee.
Lifecycle/blocked/epoch rebases and the explicit180px divergence are excluded; ordinary
moving errors still reflect inherited current-world collision replay and corrections after
changing support geometry. Those sizeable errors are disclosed, not hidden by a comfort PASS.

Master bands have measured functional evidence: clean near-ideal,80 profile comfortable,
150 profile playable,200/250 profiles in warning band. This certifies the listed functional
invariants, not subjective near-ideal/comfortable/playable feel. No numeric comfort threshold
was invented. First full local M0–M17 pass: `builds/validation/m17-full.log`; final delivery
revalidation writes `builds/validation/m17-delivery.log`. Full legacy parsers/replays/M0–M16
scenarios remain gating, plus M17 unit30/60/144 and two representative true-process cases.

## Reproducibility, telemetry and warning

M17 unit tests require identical seeded input/arrival schedules to produce equal delivered
traces and complete counters; check exact fractional tick means, invalid profiles, queue
cap/expiry,100 apply/reopen/teardown cycles, bounded percentiles, classifications, convergence,
interpolation modes and200ms hysteresis. Full-process repeats intentionally allow OS/ENet
arrival noise. Combined repeat and150/250 render variants above demonstrate functional
repeatability; differing RTT/counters are not called bit-identical.

Warning unit tests: equal200 does not enter,29 ticks>200 does not enter,30 does;190 retains,
59 ticks<=180 retains,60 clears. Normal-renderer host/client250 captures show RU/EN warning.
Some150/combined samples exceed200 and can warn legitimately, regardless of scenario label.
The observer cannot alter physics or race validity. The repeat combined guest measured one
completed reconnect,1984.797ms monotonic versus1983.333ms service time in that run; the
45-tick configured drop is only the wait before reopen, not total recovery.

## Visual review and artifacts

Inspected host/client HUD captures for clean/80/150/200/250 and normal30/144 render variants.
HUD lists measured RTT, estimated one-way, simulated one-way/RTT, jitter/loss, queues,
reconciliation/history and controls. It stays in the upper-left and leaves central actors
visible. Warning has its own row below the panel without overlap. 1280x800 window preserves
16:9 gameplay: viewport PNG1280x720 omits40px top/bottom window bars.1920x1080 PNG is full
content. Screenshot is presentation evidence, not smoothness; bounded60Hz position traces,
remote-step percentiles and1Hz telemetry traces accompany JSON reports.

Successful final monotonic-RTT matrix folders (under ignored `builds/validation`):

- `m15-clean-20-60-b9b6d2b3ef914e9fbcb240ef0151871c` — clean.
- `m15-rtt80-20-60-65c108aa04064a5a87dafa7bea12a21b` — 80.
- `m15-rtt150-20-60-e444111d389042aa81ac02f641e2f0f7` — 150.
- `m15-rtt200-20-60-a62a84f7079b4d0e88e78d9482bbef13` — 200.
- `m15-rtt250-20-60-ba0b34dfe00c4320a8585cafe6efd871` — 250.
- `m15-combined-30-60-5e4ef16c958646dcba7ee583b81f10f6` — combined running reconnect.
- `m15-rtt200-20-60-814057796e4f46e1bb6b6fe70a5fa196` — 200 Results reconnect.
- `m15-rtt250-20-30-fa1d053c4ae74361bfb51d14943d5038` — 250 render30.
- `m15-rtt150-20-144-683e7abd53fa444c843c5a2c0c007097` — 150 render144.
- `m15-combined-30-60-da7d5fab8cc445e0b77e7d95e6b1e795` — combined repeat.
- `m15-clean-20-60-834da154777847abaa6546f93387c382` — profile switches.
- `m15-rtt250-20-60-d1ac5d08b13a43dea14775a1884e7a3f` — host drop.

Each folder contains host/client stress.json, evaluation.json, local logs and rendered
screen-*.png where requested. No images/logs/private paths/bearers/persistent UUID are committed.
Unit logs: m17-unit-recovery.*, full unit render variants m17-stress-*.stdout.log.
Windows PowerShell5.1 actual two-process pass: m17-powershell51.log.

## Failures found and limitations

Initial work caught a rejected patch format (no partial mutation), a Windows Python locale
UTF-8/CRLF write error and an early screenshot with warning too close to controls. The bad
script run hit its owned-process hard timeout (m17-extended.log); it is not recorded as a
network PASS. Encoding/layout were repaired and the matrix repeated. Old service-tick RTT
skewed between loaded30FPS processes; monotonic timing now measures RTT while the legacy
service-clock estimate is reported separately, without changing the protocol.

No historical dynamic-world rollback, physical WAN/Linux/Steam Deck/controller certification,
production diagnostics, EOS/Steam/lobby/series work or new dependency. Local export templates
are absent; CI installs verified templates and tests exported ordinary/network boots and
real exported host/client. No local export pass is claimed. Required PR CI retains its20min
cap; extended12-case matrix is a separate optional dispatch step to avoid repeating each
40s renderer/boundary case on every PR. CI/remote SHA is verified in the delivery response.

## Manual review

From the main folder:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\dev_tools\start_local_network.ps1 -Godot C:/Godot/Godot.exe -Profile rtt150
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\dev_tools\test_network_stress.ps1 -Godot C:/Godot/Godot.exe -Extended -Rendered
./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe
```

Keep both windows open, wait for authoritative3/2/1/GO and move independently. F2 chooses
NEXT, F3 applies locally, F4 clean, F5 metric reset. Apply both endpoints for symmetric
conditions. F8 drops, guest F9 reconnects; F6 Ready and host F7 retries Results. Inspect
motion/corrections, warning and resume; then close both windows and review offline Solo.
Detailed commands, custom JSON fields, sampling formulas and cleanup policy: NETWORKING.md.
User manual review and separate merge authorization remain required. Do not merge or start M18.
