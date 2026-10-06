# M25 developer manual QA and approval sheet

Do not reuse prior milestone approval as approval of this artifact. Copy exact archive SHA-256
from the attached `staging-manifest.json` before testing. Leave every result blank until the
named physical/subjective check is actually performed.

Candidate version: `0.25.0-rc.1`  Build: `31`  Channel: `STAGING`

Source SHA: `a56d530fac5c8bee4d7c6961065812f57125584a`

Windows archive SHA-256: `0ba6e9096b66e06878cc2d3399bfbc6a58139db0b370a025c47f0da1bbc03c0c`

Linux archive SHA-256: `178807cfa04fc3d855e0a094e714a76ec5f5a924680b3332893ef5702b30b350`

SteamOS archive SHA-256: `178807cfa04fc3d855e0a094e714a76ec5f5a924680b3332893ef5702b30b350`

Use `PASS`, `FAIL`, or `BLOCKED`, plus a short note/evidence path. Use a new isolated OS user or
back up real data; the package tests must not overwrite an existing ProjectVelocity save.

| Step | Exact procedure and expected result | Result | Note/evidence |
| --- | --- | --- | --- |
| Windows clean package | Verify SHA-256, extract to a new directory, run `ProjectVelocity.exe`; STAGING watermark, splash/menu and no OS/application crash. Record SmartScreen warning; do not bypass security policy. |  |  |
| Windows sizes | Check 1280×720, 1280×800 and 1920×1080 windowed; fixed competitive frame, readable text/focus, no clipping. |  |  |
| Linux distro package | Verify SHA-256, extract tar preserving mode, run `./run-projectvelocity.sh`; STAGING watermark/menu, audio and no missing-library/crash. Record distro/version/session. |  |  |
| Physical Steam Deck | Game Mode/Desktop Mode as applicable at 1280×800; launcher, controls, prompts, focus, suspend/resume, audio and exit. Ubuntu/Xvfb does not satisfy this row. |  |  |
| Keyboard/mouse | Complete onboarding/menu/settings/Solo navigation and gameplay; prompts switch correctly and no stale input enters a race. |  |  |
| Physical controller/hotplug | Test an identified USB/Bluetooth controller: boot, disconnect/reconnect, D-pad/stick/face/shoulder controls, correct prompt family and safe fallback. |  |  |
| Full Foundry clean run | New isolated save; complete all seven mandatory checkpoints and Finish without dev manipulation. Expected roughly 1–2 minutes, readable hazards/camera and valid result. |  |  |
| Time Trial loop | Retry, held-R quick restart, death/respawn, pause, PB/splits/deltas, equal/worse run and invalid-run behavior. Restart once per release; only valid improved finish writes PB. |  |  |
| Online unavailable | Offline/no Steam/no EOS/network; open Online in EN and RU. Create/Join disabled, localized reason and focused Back; no crash, fake lobby/code or credential prompt. |  |  |
| RU/EN UI | Onboarding, menu, map select, settings, pause, checkpoint/skipped Finish and results in both languages; no untranslated keys/overlap. |  |  |
| Display/settings | Apply/Keep, Revert, 15-second rollback, Alt-Tab/restart at representative modes. Last confirmed mode survives; rejected mode does not. |  |  |
| Audio/accessibility | Master/music/SFX/UI/ambience routing/mute; High Contrast, colorblind modes, flash-disabled, text/UI scale, HUD opacity and screen shake. Gameplay timing unchanged. |  |  |
| Visual/readability | Local/30% opponent treatment, state/ability cues, checkpoints/Finish, spikes/saws/lasers/turrets and warning direction remain legible without relying only on color. |  |  |
| Reconnect supported scope | Development/local ENet only if intentionally using a non-production developer build. Do not expect or claim this in the release export; production Online remains unavailable. |  |  |
| Low-end performance | Approved older 4-core i5/Ryzen3, 8 GB, GTX1050Ti/RX570, 1080p Low; run M24 route/station profile three times and attach sanitized results/profiler. |  |  |
| Deck performance | Physical Deck Balanced and Performance, 1280×800, controlled power/thermal/shader-cache state; route/station/network-client profiles three times. |  |  |

Developer verdict: `APPROVE STAGING CANDIDATE` / `REJECT` / `MORE EVIDENCE REQUIRED`

Name/date: __________________________________  Notes: ______________________________________

Approval here does not merge the PR or publish a release. Those are separate explicit actions.
