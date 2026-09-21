# M20 Online Lobby UI — service contract and validation

Base: origin/dev `100ee8d04f18f1cda2720b8c1309b90f3ba72951` (M19 PR #20).
Main folder only: `C:/Godot Projects/ProjectVelocity`; branch `feature/m20-online-lobby-ui`.
Build 0.20.0-dev / 26; protocol 3 / wire 2; save schema 5 unchanged.

## Two independent acceptance decisions

- M20 UI/contract: **PASS** on the available local Godot 4.7.2 Windows checks below.
- Live EOS end-to-end: **BLOCKED**. M19 platform/Auth/Connect/native Lobby/P2P executor,
  authorized test identities, licensed full SDK/templates and two-standalone-client Internet
  evidence remain absent. No UI fake, editor, ENet or native-load test upgrades that result.

## Delivered contract

AppUI owns one LobbyPage and LobbyClient subscription. LobbyPage uses the M11 theme,
transition, scroll/focus loop, device prompts and exclusive modal focus restoration.
Production constructs the unavailable LobbyClient. There is no CLI flag, credential-presence
switch or test fake in production/export composition. Create and Join remain disabled and
Back remains focused while native capability is missing. Direct unavailable calls fail cleanly.

LobbyClient is the narrow presentation port, distinct from M19 LobbyService's low-level
create/search/admission policy. The future native executor must bridge that policy and
OnlineService Auth/Connect to this port; this milestone does not claim that bridge exists.
Only allowlisted localization keys and detached LobbyView snapshots cross into presentation.
No lobby handles, PUIDs, tokens or persistent UUIDs are rendered. Nicknames are display-only.
A view has exactly a host slot and a guest slot; no variable-size member list can admit a third.

Create and Join have pending, success, failure, cancellation and retry screens. Join uses the
existing M19 6-symbol alphabet `ABCDEFGHJKMNPQRSTUVWXYZ23456789`; edge whitespace and ASCII
case canonicalize, internal whitespace/Unicode/punctuation/ambiguous characters fail. Typed
or pasted input is never silently truncated to six valid characters. The controller keyboard
reuses NameKeyboard with code-only keys; accepting still runs ordinary join validation.
LobbyClipboard copies only canonical public join codes and provides a manual-copy fallback.
It never reads the clipboard. Tests replace it and do not overwrite the user's clipboard.

MatchSettings carries one map and 1..10 rounds. Reserved playlist/modifiers must remain empty
in v1; future support requires a versioned contract. MapCatalog supplies local MapDefinition
names, difficulty, expected duration, version and declared checksum prefix for presentation.
The executor still must validate actual protocol/build/map/version/checksum before admission.
Errors for these categories exist at this port; they are not claims of native EOS result mapping.

UI never modifies authoritative Ready, settings or game state. It sends ready/settings/start
intent tagged with the current host revision. Pending mutations disable Start synchronously,
including before signal dispatch. Host revision updates are monotonic; operation callbacks
carry generation and request ID. Unsolicited updates cannot acknowledge a pending operation.
Timeout closes the composition conservatively because an unacknowledged mutation has an
unknown outcome. Cancel, failure and leave invalidate generations and call executor cleanup.
Future native cleanup must also destroy/leave late successful creates/joins, even after the UI
has discarded their callbacks. Terminal membership loss uses fail; operation errors must use
operation_failed with both tokens. Duplicate/out-of-order snapshots cannot restore old Ready.

The deterministic test-only FakeLobbyClient revalidates host/guest permissions and revisions,
atomically publishes settings + compatibility metadata + withdrawn guest Ready, and reuses
M16 ReadyStart for guest readiness. Accepted Start records a handoff only; it does not invent
GO, load a fake race or bypass M16 loading/hints/round authority. Native atomic publication,
service capacity arbitration, private-code visibility and actual gameplay handoff remain M19
blocked integration work. There is no host migration or fake production reconnect.

## Reproduce

```powershell
./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe
# Additional normal-renderer GUI suite (use a bounded Start-Process -Wait launcher):
C:/Godot/Godot.exe --path . --script tests/lobby_ui_test.gd -- --render-capture
./dev_tools/check_eos_prerequisites.ps1
```

The validator explicitly executes M20 contract/UI suites in addition to every prior GDScript
suite. FakeLobbyClient is a fixture, not a SceneTree suite. M18 native/launcher gates remain
separate commands/CI jobs. The extended M17 process matrix remains an explicit additional run.
Normal GUI captures use synthetic input and isolated temporary saves. They establish GUI
navigation, not physical controller/Steam Deck driver support. Existing logical 1920x1080 UI
and aspect-preserving scaling remain unchanged at 1280x800 and 1920x1080 window sizes.

## Evidence

All following local commands exited 0; no unexpected Godot errors/warnings in successful runs:

| Validation | Result / local evidence |
|---|---|
| Full validator including every M0–M17 suite and M19/M20 | PASS; `builds/validation/m20-full.log`, final legacy `M0-M17 validation passed` marker |
| Suite discovery audit | 25 standalone test scripts, zero missing from validator; FakeLobbyClient is an excluded helper |
| Parser/static | 173 GDScript files passed full check-only; 12 changed scripts checked again after final fixes |
| Headless boot | `PROJECTVELOCITY_BOOT_OK`; build26 and both map hashes retained in `boot.stdout.log` |
| Final M20 contract | `PROJECTVELOCITY_M20_CONTRACT_OK live=false native=false`; `m20-contract-final.*.log` |
| Final M20 GUI headless | `PROJECTVELOCITY_M20_UI_OK live=false native=false simulated_input=true`; `m20-ui-final.*.log` |
| Final normal-renderer GUI | Same M20 UI marker; OpenGL Compatibility / AMD Radeon; `m20-render-final.*.log`, empty stderr |
| Extended M17 matrix | All 13 cases PASS, `PROJECTVELOCITY_M17_MATRIX_OK`; `m20-extended.log` (includes renderer boundary cases) |
| M18 native Windows | 20 headless + 3 rendered invalid-platform cases PASS; `m20-native.log`, `m20-native-rendered.log` |
| M18 launcher failures | Environment restored, zero native files left and negative checksum check PASS; `m20-native-launcher.log` |
| Git | staged/unstaged whitespace PASS; project.godot excluded and original SHA256 preserved |
| Local EOS/export prerequisites | All nine presence checks false; Windows/Linux templates absent; live gate BLOCKED |

Contract coverage includes create/join, all allowed code characters and invalid/canonical input,
exact two-slot views, detached snapshot isolation, Ready toggles, guest permissions at both
presentation and fixture authority, map/round reset + metadata, synchronous pending Start guard,
stale generation/revision/request rejection, notification-before-ack delivery, cancellation,
timeouts, all 14 allowlisted errors plus redaction of unknown service text, disconnect and repeated
cleanup. GUI coverage uses real mouse/keyboard/controller events for create, code-keyboard entry,
map selection, rounds, Ready, Start and leave, plus modal cancellation/focus restore and device
prompts. All defined error screens are rendered. Twelve repeated UI lifecycles retain one service
subscription; freeing AppUI removes it and leaves the composition.

Inspected normal-renderer captures: host lobby in RU/EN at both 1920x1080 and 1280x800 window
sizes, guest view, code keyboard, joining, host-left error and unavailable production entry.
The 1280x800 window keeps the existing 16:9 logical canvas; viewport image is 1280x720 inside
the aspect-preserving window. Text, code, player slots, controls and focus rings are readable.
Initial pre-final UI harness run was stopped while investigating its duration; it is not counted
as acceptance. Subsequent bounded headless and rendered final runs completed successfully.

PR and exact review-SHA CI results are checked at delivery and linked in the PR/final report.
Local export and Linux/SteamOS acceptance are not claimed; ordinary Windows Staging export and
Linux native-load checks belong to the existing CI workflows. Previous M19 artifact-quota failure
is not presumed fixed: an upload failure must remain a failed CI result, never be suppressed.

Local artifacts are ignored under builds/validation and
builds/m11-*-m20.png (legacy capture helper prefix). Credentials/vendor binaries/user saves
are excluded. project.godot is user-owned and must retain SHA256
`5b9713aca5045dd697ea09df21e9de658283b782b3b0c8f2cc540539fabb65ac` byte-for-byte.

No automatic merge and no M21. The developer reviews the PR into dev manually.
