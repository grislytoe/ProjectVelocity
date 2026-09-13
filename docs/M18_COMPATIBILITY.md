# M18 — EOSG 2.3.0 critical compatibility gate

## Executive verdict: BLOCKED — stop for developer review

This is a documented blocker delivery, **not production EOS integration or overall
compatibility proof**. Windows and Linux native-only evaluation passed. A configured EOS platform,
online identities, Lobby/P2P, full plugin installation/export, and SteamOS acceptance
have not been proven. No incompatible replacement dependency or transport is introduced.

Main folder: `C:/Godot Projects/ProjectVelocity`. Branch:
`feature/m18-eos-compatibility-gate`, base `28336864d9e76ec8f483558be6f7bce183049379`.
Fetch confirmed exact `dev == origin/dev`; base CI
[34741303314](https://github.com/grislytoe/ProjectVelocity/actions/runs/34741303314)
was running when the branch was created and subsequently completed successfully.
No worktree or project copy was created locally.

Build **0.18.0-dev /24**, candidate **EOSG 2.3.0**, gameplay **protocol3/wire2**,
save **schema5**. M0–M17 transport-independent architecture, simulation, codec, prediction,
reconciliation, hazards and M17 emulator remain unchanged. **ENet remains the default**.
User-owned `project.godot` is excluded from the commit and retains SHA256
`5b9713aca5045dd697ea09df21e9de658283b782b3b0c8f2cc540539fabb65ac` byte-for-byte.

## Exact provenance and licensing boundary

Primary [release 2.3.0](https://github.com/3ddelano/epic-online-services-godot/releases/tag/2.3.0),
published **2026-06-09T09:23:29Z**, tag/commit
`e84320567a3a17d305478f5796707e69d2bdac4f` (verified with `git ls-remote`).
SDK release declared by the author: **EOS-SDK-53289219-Release-v1.19.1.2**.
Windows native runtime independently reports **1.19.1.2-53289219**.
The pinned [README](https://github.com/3ddelano/epic-online-services-godot/blob/e84320567a3a17d305478f5796707e69d2bdac4f/README.md)
claims Godot4.2+ and Windows x64, Linux x64/arm64, Android x64/arm64, macOS, iOS arm64.
That is an upstream claim, not an exact4.7.2/SteamOS test result.

The pinned [build workflow](https://github.com/3ddelano/epic-online-services-godot/blob/e84320567a3a17d305478f5796707e69d2bdac4f/.github/workflows/build.yml)
uses `godot-cpp` tag `godot-4.2-stable`, Windows MinGW and Ubuntu24.04 Linux runners.
Its private EOS SDK mirror ref is `819cd0ffb3be1b28576bb9f23c502bec6c182d6b`.
That private mirror was not accessed; SDK build provenance beyond the public workflow,
asset hashes and runtime version is not independently reproducible here. No fork/repack
or different candidate version was used.

| Exact release asset | Bytes | Verified SHA256 |
|---|---:|---|
| `epic-online-services-godot-windows-e84320567a3a17d305478f5796707e69d2bdac4f.zip` | 9992710 | `f8fb24b8c92cd89ce810a4052afaaa267c9d22d165407c6f908456d185baa750` |
| `epic-online-services-godot-linux-e84320567a3a17d305478f5796707e69d2bdac4f.zip` | 45476064 | `d4a6bb5d5d0684afd03b76bce8c97776f7430166262d3430dacf197428feb35d` |

Both SHA256 values match GitHub release asset metadata and locally downloaded complete
archives. Independently computed SHA512:

```text
windows f7c87bf50ea525f4933808ca1df51add14fd23112b59dbeed7f51c3acca5ea6b27ff3af1bc29014d75272c3ad6659cebeda795a8ccecf234447965dd5f312b4f
linux   07361554d21256cab4b323194d2c7b2dc4e9b5e7619f219cd290cbace709175d72a38b525f2356c8c8bb2c1364d85dd81c1864cb9122b541e11ca704e866e568
```

Download only from the release's `/releases/download/2.3.0/<exact asset>` URLs.
The inspector has committed SHA256 pins and rejects mismatches before extraction/use.
An initial90s Windows transfer timed out; resume completed and the full hash matched.
Partial downloads never ran. The other download completed normally.

EOSG wrapper [license at the pinned commit](https://github.com/3ddelano/epic-online-services-godot/blob/e84320567a3a17d305478f5796707e69d2bdac4f/LICENSE.md)
is MIT, copyright Delano Lourenco2022. It permits commercial use/distribution with the
notice retained; this applies to the wrapper, not a relicensing of Epic's SDK.

[Epic Developer Agreement](https://onlineservices.epicgames.com/services/terms/agreements)
(displayed update15Feb2024; Standard Services addendum17Jun2025), §§3.1,3.3,6.3,6.5,12:
evaluation and game integration are conditional grants; distribution is limited to
designated Distributable Code in object form as part of a game with the required EULA
disclaimer. SDK access requires an account; notices must be retained and SDK third-party
terms are supplied separately. This does not by itself certify our Steam or free
standalone package. Neither price nor storefront removes those obligations.

**Redistribution blocker:** both inspected archives contain only the wrapper LICENSE.md;
no Epic SDK agreement/ThirdPartyNotices or complete designated Distributable Code manifest.
We have not obtained the licensed full1.19.1.2 SDK package from the
[Epic Developer Portal](https://dev.epicgames.com/portal/sdk) to reconcile those components,
notices and XAudio redistribution requirements. This is unverified clearance, not a claim
that Epic categorically prohibits this game. Do not commit/rehost the ZIPs/DLLs/SOs or
publish an EOS-bearing export until the developer supplies/reviews that exact package.
No Epic terms were accepted through a portal on the developer's behalf.

## Installation and native evidence scope

The official installation copies the addon into `res://addons/` and enables its editor
plugin. Source inspection found11 autoload additions, a per-frame `IEOS.tick()` controller,
an export hook selecting `features[2]`, and a disable hook that omits removing HSessions.
These are integration review concerns, not demonstrated runtime incompatibility.
We deliberately did **not** enable that editor plugin or modify project autoloads.
Full official plugin installation is therefore **BLOCKED/unverified**.

The installed evaluation subset is the **unaltered official native descriptor, native
libraries and MIT notice**, extracted into an ignored, uniquely owned test directory,
then explicitly loaded using `GDExtensionManager.load_extension`. No wrapper GDScript
autoload executes. This is a native-only capability probe outside the production transport
composition, not an EOS transport adapter claiming gameplay readiness.
The committed probe uses only the pinned IEOS low-level signatures. Native options mirror
the fields actually read by the pinned C++ source; no replacement EOS SDK is implemented.

Inspection before installation: Windows56 entries/25761913 expanded bytes; Linux57 entries/
121525281 bytes. Common contents:21 GDScripts, plugin.cfg, GDExtension descriptor, UID
metadata, README/LICENSE and platform binaries. No `.import` payload, installer EXE,
PowerShell or shell script was found in the Windows archive. The inspector rejects
traversal, absolute/colon/backslash paths, unexpected roots, duplicate paths, symlinks and
oversize archives. Extraction refuses overwrites and confines destinations to owned dirs.
No imported script or binary is committed. `.gdignore` prevents ordinary editor discovery.

Native descriptor: `eosg_library_init`, `compatibility_minimum=4.1` (upstream metadata),
separate debug/release x86_64 DLL/SO paths and dependency mappings. Linux also includes
arm64 artifacts; these are not the requested SteamOS architecture. The same x86_64 Linux
asset is the candidate for SteamOS, but execution there remains required.

Windows11Pro10.0.26200 x64, exact Godot4.7.2.stable.official.ed1daf0bf:

| Cell | Status | Evidence / exact limitation |
|---|---|---|
| Archive provenance, SHA256/SHA512 and path inspection | PASS | Both platform assets inspected; no substitution |
| Windows x86_64 editor binary, headless native load/API/init/shutdown | PASS |20 separate processes, each load0/init0/shutdown0/exit0 |
| Windows normal renderer native load/init/shutdown | PASS |5 separate Compatibility-renderer processes, exit0; no gameplay smoothness claim |
| Explicit opt-in absent | PASS | `M18_OPT_IN_REQUIRED`, exit2 before native loading |
| Missing extension path | PASS | `M18_BLOCKED category=missing_native_library`, exit2 |
| Invalid platform IDs / empty client config | PASS |3 processes, `M18_INVALID_PLATFORM rejected=true`, shutdown0/exit0; no service login |
| Configured platform creation and real EOS platform ticking | BLOCKED | No product/sandbox/deployment/client configuration; tick without platform is only a safe no-op |
| Scene reload, created-platform teardown, leak/handle/thread accounting | BLOCKED | Only global SDK lifecycle and process exit tested; no created-platform lifecycle proof |
| Windows editor plugin enabled / cold full addon import | BLOCKED | Native subset only; autoload/export/disable behavior not accepted |
| Windows EOS-bearing debug/staging/release export | BLOCKED | Local templates absent; native package/notices and full export plugin behavior unverified |
| Linux x86_64 headless native/API/lifecycle on clean CI checkout | PASS | CI34751290263/job103708170118:20 processes +3 invalid-platform cases, exit0 |
| Linux renderer/editor/full plugin/export | BLOCKED | No full plugin/export evidence at this report revision |
| SteamOS/Steam Deck x86_64 | BLOCKED | No representative SteamOS/Deck runner; Ubuntu is not Deck certification |
| Auth account identity → Connect Product User ID | BLOCKED | No live credentials/test accounts/dev-auth process; no identity returned |
| Two-process Lobby create/search/join/member/update/leave/destroy | BLOCKED | Requires two real test identities and configured client policy |
| Two-process P2P bidirectional socket/channel/data/cleanup | BLOCKED | Requires Connect identities, real connection requests, accept policy and payload tests |
| Invalid live credentials, offline/service failure, peer exit mid-flow | BLOCKED | Native malformed configuration is not these online tests |
| Malformed/oversize P2P packet and channel validation | BLOCKED | No live P2P socket; source/API inspection is not execution |
| Ordinary application / M0–M17 full Windows regression | PASS | `builds/validation/m18-full.log`, validator exit0; all previous ENet/stress gates retained |

PASS applies only to the named operation. Overall **BLOCKED** remains even if native CI
passes. No mock/unit result is counted as live service evidence. No live Epic credentials
were present in the invoking process (EOS/EPIC/PV_EOS environment names checked without
printing values); unprovided external accounts or repository secrets are not assumed absent
from the developer's possession.

Real CI evidence on commit `8139d7f25398476f07216af8943a2a9b3d1130e5`:
[native run34751290263](https://github.com/grislytoe/ProjectVelocity/actions/runs/34751290263)
completed successfully for both Windows and Linux. Linux environment: Ubuntu24.04.5LTS,
kernel6.17.0-1022-azure x86_64, glibc2.39-0ubuntu8.8. Each job performed a fresh checkout/import,
20 native process starts and3 invalid-platform process starts. Sanitized evidence artifacts:
`M18-linux-native-evidence` (id10315866198) and `M18-windows-native-evidence` (id10315564624).
They contain only logs/hash inventories; no binaries. Final PR19 head CI is checked again
at delivery, separately from these immutable historical run references.

Global lifecycle observation: an initial exploratory harness tried initialize→shutdown
twice in one process. First returned0/0, second initialize returned15 (`AlreadyConfigured`),
with logging callback `EOS_NotConfigured`; exit1. This is preserved as a failed experiment,
not a pass or proof of ABI incompatibility. The delivered harness initializes once per
process and tests repeated starts using independent processes. It guards duplicate stop,
releases platform before global shutdown, and never intentionally reinitializes after
shutdown. A future scene-lifetime adapter must keep global SDK ownership separate from
scene/platform ownership; that adapter has not been proven here. Epic's
[platform documentation](https://dev.epicgames.com/docs/epic-online-services/eos-fundamentals/eos-platform-interface)
was reachable but its client-rendered body was unavailable through text retrieval;
the lifecycle conclusion here is explicitly measured, not an invented quotation.

Initial API probe incorrectly expected `get_max_packet_size` to be a public GDScript
method; runtime reported it missing. Source shows the native override instead. The
corrected probe checks actual public methods, leaves payload-limit validation BLOCKED,
and does not claim the removed check passed.

## API contract and secure prerequisites for the next developer-run gate

Native singleton `IEOS` exposes platform initialize/create/release/shutdown/tick,
Auth/Connect login, and Lobby create/search/join/update/leave/destroy. Actual runtime
reflection checks these names. `EOSGMultiplayerPeer` exposes create_server/create_client,
explicit connection-request policy, polling and inherited packet/channel/close operations.
There are **no assumed IEOS.send_packet/receive_packet calls**. The source's P2P mediator
listens to Connect login and receives EOS packets; the peer routes socket/channel sends.
Inspect pinned `src/eosg_multiplayer_peer.cpp`, `src/eosg_packet_peer_mediator.cpp`,
`src/platform_interface.cpp` and `sample/addons/epic-online-services-godot/heos/hauth.gd`
before extending this harness. No production SceneMultiplayer replacement was made.

Pinned HAuth flow: developer Auth login obtains an Epic account identity; its copied Auth
access token is used in a Connect login with Epic external credential type. Connect PUID
is distinct from the Epic account ID; user-creation/continuance handling needs explicit
test-account policy. Anonymous DeviceID flow does not prove Auth and must not persist
device IDs into our logs/repository. Returned tokens/identities must remain memory-only.

Future secure configuration contract (names only; **online executor not implemented or
claimed tested in this blocked delivery**):

| Environment / GitHub secret name | Required developer provision |
|---|---|
| `PV_EOS_PRODUCT_ID`, `PV_EOS_SANDBOX_ID`, `PV_EOS_DEPLOYMENT_ID` | Same entitled test product/deployment for both processes |
| `PV_EOS_CLIENT_ID`, `PV_EOS_CLIENT_SECRET` | Client policy granting required Auth/Connect/Lobby/P2P operations |
| `PV_EOS_DEV_AUTH_ENDPOINT` | Developer Auth Tool endpoint reachable from test runner |
| `PV_EOS_DEV_AUTH_NAME_A`, `PV_EOS_DEV_AUTH_NAME_B` | Two distinct authorized test users stored in that tool |
| `PV_EOS_SDK_ARCHIVE` | Private provisioned exact1.19.1.2 SDK archive with notices; local path only, never uploaded |

These PV names are our proposed contract, not SDK-native environment variables. They are
not read by the native-only harness. Never supply ClientSecret, exchange codes, credentials,
tokens, DeviceIDs or account identities in chat, command arguments, committed resources or
CI output. Bind GitHub secrets only to an explicitly approved private online job with no
untrusted PR code. Current CI uses no Epic credentials and makes no login attempts.

Developer-side prerequisites: licensed SDK and notices; registered Epic product; matching
sandbox/deployment; client policy; Auth application/scopes/test access; two test accounts
with consent/access; Dev Auth Tool reachable to two isolated processes; permitted network
access. After these exist, implement bounded online callbacks and log only allowlisted
result codes/boolean identity-present markers, never whole dictionaries or raw SDK logs.
Require two processes, isolated users/cache/logs, explicit request acceptance for the
expected peer, socket/channel/payload rejection, timeout and peer-exit cleanup.

## Reproduce without secrets

Use the main folder and PowerShell7 on Windows or CI. Download the exact asset from the
release above into ignored `.tools/m18/`; no download is required for ordinary F5/Solo/ENet.

```powershell
./dev_tools/inspect_eosg_candidate.ps1 -Platform windows -Archive .tools/m18/windows.zip
./dev_tools/test_eosg_native.ps1 -Godot C:/Godot/Godot.exe -Platform windows -Archive .tools/m18/windows.zip
./dev_tools/test_eosg_native.ps1 -Godot C:/Godot/Godot.exe -Platform windows -Archive .tools/m18/windows.zip -Rendered -Repetitions 5
./dev_tools/test_eosg_native.ps1 -Godot C:/Godot/Godot.exe -Platform windows -Archive .tools/m18/windows.zip -InvalidPlatform -Repetitions 3
./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe
```

Expected markers: `M18_ARCHIVE_INSPECTED`, `M18_API_SURFACE_OK`, SDK version,
`M18_INITIALIZE ... result=0`, `M18_SHUTDOWN ... result=0`, `M18_NATIVE_ONLY_OK`,
`M18_PROCESS_OK ... exit=0`, `M18_NATIVE_MATRIX_OK ... online=BLOCKED`.
Missing opt-in/native file: exit2 with actionable classification. Bad hash: terminating
`M18_CHECKSUM_FAIL`, no extraction. Other native failures terminate with nonzero exit;
missing dependencies/ABI failures require loader output and binary dependency inspection
to distinguish them, not a misleading credential error.

The launcher isolates APPDATA/LOCALAPPDATA/XDG paths for every child, bounds each process
to30s, disposes/kills only its exact owned process and restores the parent's environment.
It removes its exact extracted native candidate after use and retains sanitized local
logs. No native files/cache/save folders may be uploaded with those logs.
Direct exploratory extraction remains ignored under `.tools/m18/native-windows`.

CI `eosg-gate.yml` verifies both pinned candidate hashes, then uses fresh Windows/Linux
runners for the native subset. Evidence uploads are restricted to stdout/stderr and hash
inventories, not SDK binaries or user data. `validate.yml` retains the complete M0–M17
Windows validator and ordinary Windows staging/exported ENet acceptance. Those ordinary
exports contain no EOS addon, and their success is not an EOS export PASS.

## Binary and security inspection

Windows PE machine fields are AMD64(0x8664) for both wrappers, EOSSDK and XAudio.
Both wrapper DLLs import EOSSDK-Win64-Shipping.dll and KERNEL32.dll. SDK imports include
VC++ runtime MSVCP140/VCRUNTIME140/VCRUNTIME140_1, UCRT and Windows network/crypto libraries;
successful load proves these were resolved on this machine only. Authenticode reports
Valid for EOSSDK/XAudio and NotSigned for both wrapper binaries; this is not malware
certification. Full per-binary SHA256 inventory is reproducible with the inspector.
Linux CI records ELF architecture/dynamic dependencies; no Windows inference is used as
Linux load evidence.

Linux wrapper ELF headers:64-bit LSB x86-64. Debug build ID
`00486ef41fa6a4acd1e0aca0807c14ed8f144c48`, release build ID
`8db20c53428e51c1369033d67fe1a77c3aac8cf6`. Both declare dependencies on
`libEOSSDK-Linux-Shipping.so`, `libm.so.6`, `libc.so.6`, `ld-linux-x86-64.so.2`.
Initial CI inventory's `ldd --version | head -1` emitted harmless broken-pipe diagnostics;
the delivered workflow prints the full version and includes the SDK ELF dependency list.
No native failure was hidden or retried to obtain that run's PASS.

Wrapper debug/release SHA256, respectively:

```text
Windows e6a199753d1ae46b0d453480040a65d51144ebdfe2506f8ff7498baac2d4dcd3
        4f04f557ebc8e4fb873b389b2363db70f0e4187cf6b3094dd644cd00e46b9c00
Linux   3a949ab966a536522cc4f1872e279e526bb30101fc3652701d4cd2a01238881d
        db52da6ed320b23bcc61fea566d90a7ccbb6d4134dd2f4ca0c7ae98e7390b2f0
EOSSDK-Win64-Shipping.dll     9c498fe31c8df1d9085dfa9c71c6d50ec6b569acdb29f1decb97be105b6341dc
libEOSSDK-Linux-Shipping.so   943bd5247b1b6cb783209b70ef672bfabb12b80a88151e6cfd7eca57dcbfcc4d
xaudio2_9redist.dll           0e01f400baa09694cacfd2cfbff0d721c17b56785d2d6e29b6fdd117f70ccc1e
```

All fetched source stays ignored. No third-party script executes in ordinary builds;
critical plugin/runtime/export/platform/auth/P2P sources were reviewed. No comprehensive
native vulnerability audit, compiler reproducibility, handle leak proof or malware
certification is claimed. A signature scan of all reachable Git history and working files
found0 high-confidence GitHub/AWS/private-key signatures; this is a limited scan, not
proof that every possible secret format is absent. Staged content must also be reviewed
before commit; real product credentials, saves, native caches, binaries and logs are excluded.

## Developer decision gate

Accept this **BLOCKED** report/tooling PR for review only, or provide the exact SDK/notices,
secure Epic test configuration and a suitable SteamOS runner to resume M18 in a separately
authorized validation pass. Review the full plugin's global lifecycle/autoload/export
behavior before enabling it. Missing credentials are not binary incompatibility, and
native loading is not Auth/Lobby/P2P proof. No overall PROVEN verdict, dependency
replacement, production integration, merge or M19 is authorized by this delivery.
