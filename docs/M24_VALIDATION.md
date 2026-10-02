# M24 Performance and Benchmark — validation evidence

Date: 2026-10-02. Branch `feature/m24-performance-benchmark`, base `origin/dev`
`492cb82070130b8738fdeb2e6ecf38ec52b25a63`. Runtime **0.24.0-dev / build30**;
protocol **5**, wire **4**, save schema **5**. Godot
**4.7.2.stable.official.ed1daf0bf**, Compatibility/OpenGL3.

Actual local machine: AMD Ryzen 7 7730U (8C/16T), integrated AMD Radeon Graphics driver
31.0.21925.1001, 16,540,782,592 bytes installed RAM, Windows 11 Pro 10.0.26200, Balanced power
profile. Desktop was 1920×1200. No machine/user name, path or hardware ID is retained. This is
neither the approved low-end discrete-GPU class nor Steam Deck/SteamOS and cannot certify either.

## Baseline and profiler findings

Unmodified M23 at the approved base, normal renderer, 180 paced frames: p50 **16.652 ms**,
p95 **18.608 ms**, max **19.351 ms**, 103 draw calls, 3030 primitives and **1470.461 ms** direct
Foundry construction. The first M24 worst-station unpaced run (same local machine, Low 1080p,
30 warm/180 sample) measured p50 **3.465**, p95 **4.563**, p99 **11.642**, max **14.698 ms**,
193 draw calls, 5773 primitives and **1359.132 ms** construction.

Profiling/tracing identified only three justified changes:

1. SoloTrial performed the complete structural/semantic/checksum validation and immediately made
   SoloCourse repeat it on the exact same Resource. The owner now marks only that exact just-
   validated transaction as prevalidated; direct/editor/network composition still validates.
2. Player module draw lists were rebuilt every fixed tick although only transforms/modulate moved;
   module geometry now redraws only when emission/style changes. Root VFX redraw on visible cue
   changes and every expanding Double Jump ring tick.
3. Cyclic hazard geometry rebuilt between unchanged phases, turrets rebuilt while angle/state was
   unchanged, and the M17 developer HUD formatted/layouted a large diagnostic block at 60 Hz.
   Hazards/turrets now redraw on visual changes; HUD/overlay updates at 10 Hz while telemetry,
   physics and network service remain 60 Hz.

The same pre-extra-turret hotspot composition after changes measured p50 **3.408**, p95 **4.206**,
p99 **4.666**, max **5.555 ms** (three Low runs had p95 4.206–4.397 ms). The later final station
is deliberately heavier: three dual-channel turrets, 10 live pooled projectiles, p50 **3.495**,
p95 **4.594**, p99 **5.673**, max **14.539 ms** unpaced. No blind rewrite or gameplay-rate change
was made. Cold-ish direct construction remains **1.34–1.38 s** and is a documented loading blocker;
resource preload cannot guarantee cold driver shader compilation.

## Final local/profile results

Paced values include VSync/60 FPS scheduling and retain all threshold counts. The 4200-frame
Balanced route completed the real M14 scripted input path and Finish (`route_complete=1`).

| Scenario/profile | Samples | p50 / p95 / p99 / max ms | >25 / >33.333 | Draw p95 / primitives p95 | Verdict |
| --- | ---: | --- | ---: | ---: | --- |
| Foundry traversal, 1280×800 Balanced paced | 4200 | 16.666 / 17.404 / 17.725 / 23.085 | 0 / 0 | 163 / 4030 | local profile OK; certification BLOCKED |
| Worst station, 1920×1080 Low paced | 300 | 16.644 / 17.332 / 17.553 / 17.677 | 0 / 0 | 238 max / 9709 max | local profile OK; certification BLOCKED |
| Worst station, 1920×1080 Low unpaced, 3 repeats | 300 each | p50 3.408–3.454; p95 4.206–4.397; p99 4.666–5.279; max 5.122–5.936 | 0 / 0 | 193 / 5773 before added cap turrets | throughput only |
| Worst station, 1280×800 Balanced unpaced | 300 | 1.974 / 2.830 / 3.638 / 9.214 | 0 / 0 | 193 / 5773 | throughput only |
| Worst station, 1280×800 Performance unpaced | 300 | 1.997 / 2.947 / 5.394 / 9.984 | 0 / 0 | 193 / 5773 | throughput only |

The older paced Balanced/Performance station samples were p95 17.408/17.430 ms, p99
17.720/17.685 ms, max 18.021/18.060 ms with no >25 ms frames. The selected 17.5 ms p95 convention
allows half a fixed tick of Windows pacing tolerance; it does not erase the >16.667 counts.

First use: course 1343.436 ms, generated background first draw 77.576 ms, first animation
0.111 ms; pooled projectile warm/first activation 0.303 ms; menu/lobby/results first open
23.359/35.666/17.443 ms. Current committed raster decodes to 2 MiB. Compatibility exposed
texture/video-memory counters locally; platform GPU utilization/driver shader compilation time
were unavailable and are not invented.

Memory/pools: worst local working-set/private peaks were about **318.3/424.6 MB** across recorded
runs; Godot static/peak about **53.3/65.1 MB** for traversal. After one cache-establishing cycle,
10 Foundry load/teardowns produced **0 node, 0 resource, 0 orphan** growth and **2768 bytes** static
delta. Pool stress reached exactly 10 global / 5 per target and 3 engagements per target; the
over-cap path incremented skip, created no node, deferred no shot and all 10 instance IDs stayed
stable. Player VFX remain bounded immediate drawing rather than repeated allocations.

## Two-process network evidence and known stutter

Rendered local ENet races retained 60 Hz physics/service, protocol5/wire4, 20/30 Hz snapshots,
prediction/interpolation and M17 telemetry. rtt150/30 Hz and rtt200/20 Hz both converged all seven
checkpoints, winner/events, pool cleanup and authority rejection. Measured RTT was 150.5–186.7 ms
in the final rtt150 pair and 213.4–218.2 ms in rtt200; >200 warning entries occurred without
changing cadence or authority.

Two simultaneous rendered 1280×800 processes oversubscribed this integrated GPU/Windows window
scheduler: final rtt150 host active-gameplay frame p50/p95/p99/max was
16.666/17.630/26.404/90.515 ms; client 18.532/33.836/72.315/111.686 ms. Reconnect pause/results
were excluded. This is an honest local two-window blocker, not attributed to gameplay alone and
not used to fail/certify target hardware. Next action: repeat each endpoint on separate physical
target devices (or one render client plus headless peer for rendering isolation), capture Godot
CPU/GPU profiler lanes and driver traces, then address any hotspot reproduced on one endpoint.

## Identity, regression and acceptance matrix

Performance changes touch the conservative PV-MAP-1 bundle. Training publishes **v8** checksum
`fa75d8960d6ff1e3436f6ecd0ddd5446122073c0fc8e22a0f60128912498529b`; Foundry publishes **v7**
checksum `6a0d41dc3125fb01a3fcdc4206c20ebe0b2745f39deb89f2a7439be14e52ef60`.
Historical PB keys remain stored. Geometry, tuning and M3/M5/M8/M9/M10/M14 traces are required
unchanged by the full validator; protocol5/wire4/save5 remain unchanged.

| Acceptance | Status | Reason / reproduction |
| --- | --- | --- |
| Local profile/composition | PASS | Compatibility normal renderer, paced/unpaced, route/station/UI/leak/network evidence above |
| Low-end 1080p60 | **BLOCKED** | Run Low paced + unpaced three times on ≤4-core older i5/Ryzen3, 8 GB, GTX1050Ti/RX570; attach JSON/CSV and Godot profiler |
| Steam Deck Balanced 60 | **BLOCKED** | Physical Steam Deck/SteamOS, 1280×800 with 1280×720 world; three route/station/network-client runs |
| Steam Deck Performance 60 | **BLOCKED** | Same physical procedure using Performance; verify power/thermal state and shader-cache condition |
| M19 live EOS/Internet | **BLOCKED, separate** | Native Auth/Connect/Lobby/P2P/authorized identities still absent; local ENet is not acceptance |

Validation includes statistics/schema/budget unit tests, normal benchmark smoke, all M0–M24
parsers/tests, fixed-rate traces, M17 80/150/200+ coverage, headless/normal startup, real-process
ENet, map checksum, Git whitespace/status and save/secret scans. Windows staging export/boot and
exported ENet/benchmark smoke are CI responsibilities when local export templates are absent.
