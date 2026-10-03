# M25 Standalone Release Candidate — validation evidence

Date: 2026-10-03. Workspace: `C:/Godot Projects/ProjectVelocity`; branch
`feature/m25-standalone-release-candidate`; exact approved base
`origin/dev` `1b226dfc8e5efe12209822801554334847770a97`. The unrelated user
`project.godot` remains byte-identical SHA-256
`5b9713aca5045dd697ea09df21e9de658283b782b3b0c8f2cc540539fabb65ac`
and is excluded from every commit and artifact. Release builds are made from a clean committed
snapshot, never from that working tree.

Runtime candidate: **0.25.0-rc.1 / build31 / STAGING**, protocol **5**, wire **4**, save
schema **5**. Official map identities are unchanged because M25 build/release files are outside
PV-MAP-1: Training Circuit v8
`fa75d8960d6ff1e3436f6ecd0ddd5446122073c0fc8e22a0f60128912498529b` and Industrial
Foundry v7 `6a0d41dc3125fb01a3fcdc4206c20ebe0b2745f39deb89f2a7439be14e52ef60`.

## Toolchain provenance

Official Godot **4.7.2.stable.official.ed1daf0bf** and matching release templates are required.
CI downloads only from the official `godotengine/godot-builds` 4.7.2 release, first verifies the
unique entry in `SHA512-SUMS.txt`, then verifies the downloaded bytes:

| Official asset | SHA-512 |
| --- | --- |
| `Godot_v4.7.2-stable_win64.exe.zip` | `83decd58fdf67b9d657958a1ae6bf1929c20785315a81effe245874cdc57acb709bf868e00778a96984338c1b29dafdb453c6847747694621c6ecf5da2259993` |
| `Godot_v4.7.2-stable_linux.x86_64.zip` | `9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65` |
| `Godot_v4.7.2-stable_export_templates.tpz` | `ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079` |

No EOSG archive, full EOS SDK, native vendor binary, credential or signing material is downloaded
or bundled by M25. The historical M18 gate is manual/branch-scoped and does not run on this PR.

## Automated gate and commands

The exact review SHA is the candidate source identity embedded in both platform exports through a
provenance Resource patched only in the clean staging snapshot. The release script rejects a
missing/invalid 40-character SHA and the extracted
application prints it with version/channel/protocol/wire/save identity during isolated smoke.

```powershell
./dev_tools/release_source_audit.ps1 -RequireClean
./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe
./dev_tools/validate_linux.ps1 -Godot /path/to/Godot_v4.7.2-stable_linux.x86_64
./dev_tools/release_staging.ps1 -Target windows -Godot C:/Godot/Godot.exe -SourceSha <40-hex> -RenderedSmoke
./dev_tools/release_staging.ps1 -Target linux -Godot /path/to/godot -SourceSha <40-hex>
```

Windows validation runs the complete existing M0–M24 automation plus M25 identity/source audit:
parser/import, isolated boot, deterministic movement/camera/platform/hazard/Solo/map hashes,
save migration/backup/recovery, input/hotplug/controller simulation, UI/settings, Industrial
main/shortcut/recovery routes, M15–M22 authority/series/reconnect, 80/150/200+ network profiles,
malicious claims, production 2700-tick expiry, host drop, pool/leak/performance schema and Git
whitespace. Linux independently parses all scripts and runs every deterministic GDScript suite at
required fixed rates before release export. Separate-process ENet stress remains the Windows
transport fixture; it is not EOS/Internet evidence.

Release packaging then performs a release-template export, resource ZIP inventory audit, final
archive inventory audit, executable/PCK hashing, clean extraction, isolated headless smoke and
production dev-ENet rejection. Windows additionally runs normal Compatibility smokes at
1280×720, 1280×800 and 1920×1080. Linux runs `ldd` with no missing libraries, preserves executable
and launcher permissions, then runs normal Compatibility startup under Xvfb at 1280×800. The
final CI job downloads both uploaded artifacts and re-verifies every `SHA256SUMS` entry.

## Artifact evidence

The authoritative per-platform `staging-manifest.json` records schema, exact source SHA, build and
gameplay identity, archive filename/size/SHA-256, executable/PCK hashes, official toolchain hashes,
map identity and validation-log references. `SHA256SUMS` is verified after upload/download. Exact
review-run URLs, uploaded sizes and hashes are added here after the immutable candidate workflow
finishes; absence of those values keeps this row **PENDING**, not PASS.

| Artifact | Size | SHA-256 | Status |
| --- | ---: | --- | --- |
| `ProjectVelocity-0.25.0-rc.1-build31-windows-x86_64.zip` | pending CI | pending CI manifest | PENDING |
| `ProjectVelocity-0.25.0-rc.1-build31-linux-x86_64.tar.gz` | pending CI | pending CI manifest | PENDING |
| `ProjectVelocity-0.25.0-rc.1-build31-steamos-x86_64.tar.gz` | pending CI | pending CI manifest | PENDING; package compatibility only |

Byte-for-byte reproducibility is not promised: archive/export timestamps can vary. Exact hashes
identify the produced review candidate.

## Release go/no-go

| Gate | Status | Exact evidence / limitation |
| --- | --- | --- |
| Source/dependency/license/secret audit | PENDING | Must pass on immutable review SHA; Godot MIT and CI-only dependencies are inventoried |
| Complete automated M0–M25 Windows gate | PENDING | Required full validator, no suppressed failures |
| Linux deterministic/parser gate | PENDING | Independent Ubuntu 24.04 runner required |
| Windows release artifact | PENDING | Official release template, clean extraction, three normal-render sizes and isolated headless boot required |
| Linux release artifact | PENDING | Official release template, tar permissions, `ldd`, extracted headless and Xvfb boot required |
| SteamOS-compatible package layout | PENDING | Same dependency-free Linux x86_64 content, launcher/readme/permissions; Linux command line evidence required |
| Physical Steam Deck/SteamOS runtime/controller/performance | **BLOCKED** | No physical Deck evidence; Ubuntu/Xvfb is not SteamOS certification |
| Approved low-end 1080p60 target | **BLOCKED** | M24 Ryzen 7 7730U iGPU evidence is not GTX1050Ti/RX570 certification |
| Physical controller/hotplug and subjective UI/gameplay/readability | **PENDING** | Developer must execute `M25_MANUAL_QA.md` against exact hashes |
| Full clean Foundry/Time Trial/manual settings flow | **PENDING** | Automated route/state coverage is not a human artifact playthrough |
| Production EOS/Online | **BLOCKED** | M19 Auth/Connect/Lobby/P2P, two authorized Internet clients and native exports do not exist; Online remains localized/unavailable/non-crashing |
| Signing/installers/store/CDN | **BLOCKED / NOT APPLICABLE to staging** | Portable binaries are unsigned; no installer, tag, GitHub Release, Steam or public upload is authorized |
| Developer release approval | **PENDING** | PR/artifacts are reviewable staging only |

Overall release verdict: **NO-GO / READY FOR MANUAL REVIEW only after automated artifact rows pass**.
M25 cannot be approved while manual, target-hardware, Steam Deck and EOS gates remain unresolved.
Under the master v1 scope, missing production standalone Online is a release blocker, not a hidden
optional success. The PR must remain unmerged and no tag/release/publication may be created.
