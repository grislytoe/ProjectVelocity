# Performance budgets — M24

These are engineering budgets for regression detection, not quotations from the master and not
hardware certification by themselves. Gameplay invariants are fixed: physics 60 Hz; approved
20/30 Hz snapshots; unchanged input/service cadence, collision, camera authority, checkpoint and
hazard timing.

| Budget | Low 1920×1080 | Deck Balanced 1280×800 | Deck Performance 1280×800 |
| --- | ---: | ---: | ---: |
| Paced p95 / p99 frame | ≤17.5 / ≤25 ms | ≤17.5 / ≤25 ms | ≤17.5 / ≤25 ms |
| Gameplay frames >33.333 ms | 0 after warm-up | 0 | 0 |
| Worst-station draw calls p95 | ≤250 | ≤250 | ≤250 |
| Worst-station primitives p95 | ≤10,000 | ≤10,000 | ≤10,000 |
| Full benchmark nodes/resources | ≤1,100 / ≤250 | same | same |
| Godot static / peak | ≤96 / ≤128 MiB | same | same |
| Process working set / private peak | ≤384 / ≤512 MiB | same | same |
| Reported texture memory | ≤64 MiB | same | same |
| Committed raster decoded estimate | 2 MiB current; ≤32 MiB budget | same | same |
| Post-warm ten-cycle growth | 0 nodes/resources/orphans; ≤64 KiB static | same | same |
| Projectile pool | exactly 5/target, 10 global; no deferred shot | same | same |
| Turret engagements | ≤3/target | same | same |

First-use local reference budgets are ≤1600 ms cold-ish Foundry construction, ≤100 ms first
background draw, ≤2 ms first pooled projectile and ≤50 ms each menu/lobby/results first open.
They flag regressions; platform shader-cache misses remain separately reported.

Quality differences are visual only. Quality uses 48 antialiased effect segments and mipmapped
linear filtering; Balanced uses 32 antialiased segments at 75% effect alpha; Performance and
1080p Low use 16 non-antialiased segments at 50% effect alpha. All retain player/hazard/platform/
checkpoint/Finish silhouettes, readiness, opponent treatment, high contrast/colorblind support
and the fixed competitive frame. No preset changes simulation or network data.

Texture/atlas rules remain: 1024×1024 hard edge cap, target atlas about 800×800, typical character
frame 128–192 px, and no unnecessary 2K/4K sources. Repeated projectiles use the existing pool;
current player action VFX are bounded procedural draw commands with no per-use node/resource load.
