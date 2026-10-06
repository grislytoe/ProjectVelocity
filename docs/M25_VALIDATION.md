# M25 Standalone Release Candidate — validation evidence

Date: 2026-10-06. Workspace: `C:/Godot Projects/ProjectVelocity`; branch
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
The immutable exported source identity is
`a56d530fac5c8bee4d7c6961065812f57125584a`.

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

The authoritative [PR workflow run](https://github.com/grislytoe/ProjectVelocity/actions/runs/37450631012)
completed successfully on 2026-10-06. All five jobs passed: Windows validation, Linux validation,
Windows staging, Linux staging and post-upload artifact verification. The authoritative
per-platform `staging-manifest.json` records schema, exact source SHA, build and
gameplay identity, archive filename/size/SHA-256, executable/PCK hashes, official toolchain hashes,
map identity and validation-log references. The final job downloaded both uploaded artifacts and
successfully re-ran every `SHA256SUMS` check before producing the compact metadata artifact.

| Artifact | Size | SHA-256 | Status |
| --- | ---: | --- | --- |
| `ProjectVelocity-0.25.0-rc.1-build31-windows-x86_64.zip` | 39,810,523 bytes | `0ba6e9096b66e06878cc2d3399bfbc6a58139db0b370a025c47f0da1bbc03c0c` | PASS |
| `ProjectVelocity-0.25.0-rc.1-build31-linux-x86_64.tar.gz` | 29,038,397 bytes | `178807cfa04fc3d855e0a094e714a76ec5f5a924680b3332893ef5702b30b350` | PASS |
| `ProjectVelocity-0.25.0-rc.1-build31-steamos-x86_64.tar.gz` | 29,038,397 bytes | `178807cfa04fc3d855e0a094e714a76ec5f5a924680b3332893ef5702b30b350` | PASS for package compatibility only |

GitHub Actions wraps the deliverables, extracted package, manifests and validation logs in its own
download ZIP. Do not confuse these transport digests with the deliverable archive hashes above:

| Actions artifact | ID | Uploaded size | Actions transport SHA-256 | Retained until |
| --- | ---: | ---: | --- | --- |
| `ProjectVelocity-0.25.0-rc.1-build31-windows-x86_64` | `11406919751` | 79,232,461 bytes | `7d4d747b6d289dff30b59189807f00908fbd5214b58ee3882b51f92607557848` | 2026-10-20 |
| `ProjectVelocity-0.25.0-rc.1-build31-linux-steamos-x86_64` | `11407600210` | 87,666,573 bytes | `50dbbe63e58b84c3e1f3e67b9e4d0dbc16a1917db768e0d82750979238eebb1b` | 2026-10-20 |
| `ProjectVelocity-0.25.0-rc.1-build31-staging-metadata` | `11406959854` | 3,955 bytes | `aa4ca957eeb0848f9f7f69b63e1d925e10f7900a7b517568b9768d4cbc1306a8` | 2026-11-05 |

Byte-for-byte reproducibility is not promised: archive/export timestamps can vary. Exact hashes
identify the produced review candidate.

## Release go/no-go

| Gate | Status | Exact evidence / limitation |
| --- | --- | --- |
| Source/dependency/license/secret audit | **PASS** | Clean CI checkout at `a56d530fac5c8bee4d7c6961065812f57125584a`; Godot MIT and CI-only dependencies inventoried; forbidden paths/secrets/vendor scan passed |
| Complete automated M0–M25 Windows gate | **PASS** | `windows-validation` passed without suppressed failures in run `37450631012` |
| Linux deterministic/parser gate | **PASS** | Independent Ubuntu 24.04 `linux-validation` passed |
| Windows release artifact | **PASS** | Official release template, clean extraction, isolated headless plus 1280×720/1280×800/1920×1080 ANGLE Compatibility smokes passed |
| Linux release artifact | **PASS** | Official release template, tar permissions, `ldd`, extracted headless and Xvfb Compatibility boot passed |
| SteamOS-compatible package layout | **PASS (package only)** | Same dependency-free Linux x86_64 content, launcher/readme/permissions and Linux command-line evidence; not physical SteamOS certification |
| Physical Steam Deck/SteamOS runtime/controller/performance | **BLOCKED** | No physical Deck evidence; Ubuntu/Xvfb is not SteamOS certification |
| Approved low-end 1080p60 target | **BLOCKED** | M24 Ryzen 7 7730U iGPU evidence is not GTX1050Ti/RX570 certification |
| Physical controller/hotplug and subjective UI/gameplay/readability | **PENDING** | Developer must execute `M25_MANUAL_QA.md` against exact hashes |
| Full clean Foundry/Time Trial/manual settings flow | **PENDING** | Automated route/state coverage is not a human artifact playthrough |
| Production EOS/Online | **BLOCKED** | M19 Auth/Connect/Lobby/P2P, two authorized Internet clients and native exports do not exist; Online remains localized/unavailable/non-crashing |
| Signing/installers/store/CDN | **BLOCKED / NOT APPLICABLE to staging** | Portable binaries are unsigned; no installer, tag, GitHub Release, Steam or public upload is authorized |
| Developer release approval | **PENDING** | PR/artifacts are reviewable staging only |

Overall release verdict: **NO-GO for public release / READY FOR MANUAL REVIEW**.
M25 cannot be approved while manual, target-hardware, Steam Deck and EOS gates remain unresolved.
Under the master v1 scope, missing production standalone Online is a release blocker, not a hidden
optional success. The PR must remain unmerged and no tag/release/publication may be created.
