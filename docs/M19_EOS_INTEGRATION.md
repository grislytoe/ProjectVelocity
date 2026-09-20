# M19 integration contract — native execution remains BLOCKED

The compiled capability is false even if configuration later appears. Ordinary F5, Solo
and ENet neither load EOS nor inspect credentials through the menu. Online shows a localized
configuration/review message with disabled Create/Join and an accessible Back button.
No user-visible lobby ID, PUID, token, fake code or fake online success is rendered.

## Policy pieces and ownership

`core/online/online_service.gd` models OFFLINE → AUTH → CONNECT → ONLINE, with terminal
STOPPED after SDK shutdown. Auth account presence is distinct from Connect PUID presence.
Continuance means LINK_REQUIRED, never implicit CreateUser, account merge, persistent
DeviceID or nickname identity. Callbacks carry operation generation; cancellation/logouts
invalidate them. A30s total deadline covers AUTH/CONNECT. Logout permits another login while
global SDK remains alive; shutdown is process-terminal. This is **policy only**; there is
no platform creation, native ticking, token ownership, expiration refresh or SDK cleanup
executor yet. Tests cannot prove them.

The future OnlineService native owner must validate all configuration before platform creation,
initialize globally once, tick only while alive, and unwind P2P → lobby leave/destroy →
Connect/Auth logout → callback notifications/references → platform release → shutdown.
Late successful lobby creation must be destroyed even after UI cancellation; late join must
leave. No raw SDK log callback may be routed to AppLogger. Allowlist result codes/categories
only. Never serialize callback dictionaries, Epic IDs, PUIDs, tokens or continuance handles.

`lobby_service.gd` models a15s total operation deadline, a single outstanding operation,
create publication acknowledgement, code search, join admission revalidation, and closure.
Callbacks after cancel/timeout are ignored by policy; the future native boundary still owns
late resource cleanup. `admission_result(false)` requires native leave/destroy. Code appears
only after matching metadata publication acknowledgement. Capacity is exactly2. Member loss
must revoke the corresponding P2P mapping immediately; owner loss closes the composition,
never promotes the guest. Service-handle strings are internal, not user codes.

`EOSP2PTransport` matches MultiplayerTransport send/poll/close and uses the existing
NetPacket codec/PacketFragments. **Its native `open()` always returns ERR_UNAVAILABLE.**
`attach_test_boundary` is explicitly a debug-only non-live fixture seam, not an alternative
EOS implementation. No game composition calls it. Its envelope sender/socket/epoch represent
authenticated boundary facts; treating payload claims as those facts would invalidate every
membership test. EOSG's current queue cannot establish that contract merely by mapping a
claimed peer ID back to a PUID; see the source-review blocker.

Fixture packets use28-character alphanumeric socket `PV19` +24 hex epoch characters;
production would generate a fresh96-bit epoch with Crypto for every lobby/session composition.
Epoch is a routing generation, not a bearer secret. User packet fragment<=1016 bytes,
whole message<=65536;128 receives/sends per poll,256 queued outgoing fragments,32 partial
messages per reliability class,60-tick partial expiry. Reliable controls HELLO/WELCOME/READY/BYE
use logical channel1; INPUT/SNAPSHOT/PING/PONG use logical channel2/unreliable. No ordered-unreliable
assumption. Reliability classes reassemble separately. Unknown member/socket/epoch/target,
channel/type/size/framing/codec failure is rejected. Overflow rejects a whole new message;
blocked sends retry in order; close clears queues/fragments/boundary references. Real EOS
channel translation, native queue budgets, request rejection and delayed-delivery disable
are required later; these fixture bounds do not bound native memory or work.

Protocol3/wire2 is unchanged: no new gameplay payload or authority. M16 still validates
direction/session/map/generation and owns checkpoints/death/Finish/round. M17 wraps the same
transport boundary. No persistent player UUID/nickname is identity. Production mapping must
be memory-only session player1/2 ↔ accepted Connect PUIDs. EOS reconnect is **unsupported in
this delivery**; ENet's45s same-process bearer reconnect is unchanged. Future EOS resume must
require both current lobby membership and the existing bearer/session generation; bearer
alone cannot restore membership or host authority. Process restart loses the bearer.

## Code and metadata convention

Alphabet `ABCDEFGHJKMNPQRSTUVWXYZ23456789` (31 symbols); excludes I/L/O/0/1. Master specifies
uppercase Latin/digits without ambiguous characters, not this exact exclusion list. Input
trims edge whitespace and uppercases; internal whitespace, punctuation, homoglyphs and invalid
length are rejected, not guessed. Crypto bytes use rejection sampling below248 to avoid bias.
32 entropy bytes per attempt, explicit failure if fewer than6 accepted; no weak fallback.
Deterministic injection exists only for tests. At most8 collision queries; query failure aborts.
`reserve_candidate` is a candidate check, **not atomic reservation or global uniqueness**.
After real creation/update, search again to detect observed collisions; destroy/retry on conflict.
Eventual consistency can still produce duplicate codes; join refuses ambiguous results.
Code lifetime is the owner's lobby lifetime; leave/destroy closes it. A code is not a password.

Detached metadata schema (all fields required, no additional keys in this policy):

| Key | Type | Rule |
|---|---|---|
| code | String | Canonical6-symbol code |
| game | String | ProjectVelocity |
| protocol / wire | integer | Exact current3 /2 |
| build | String | Exact BuildInfo.VERSION (conservative M19 compatibility convention) |
| map | String | Local map ID,<=64 chars |
| map_version | integer | 1..65535, exact local version |
| checksum | String |64 hex chars, exact validated local map checksum |

Strings are bounded64; version integers1..65535. Native serialization must use EOS string/int64
attributes, owner-only lobby modification, searchable code and compatibility attributes with
approved visibility. Do not interpret detached schema tests as EOS attribute-limit validation.
Region/round/ready/series settings are not published by this blocked delivery. Round count1–10
and host Start after guest Ready remain requirements for the eventual full lobby screen;
M16 gameplay ready/round protocol remains authoritative.

Search uses exact code equality; complete response maximum25, exactly one compatible open
room with owner present/member count1/capacity2. Zero matches, full/stale rows, malformed
metadata, duplicate handles, multiple distinct matches and incomplete/truncated search cannot
autojoin. Revalidate after service join to catch concurrent capacity/settings change. Native
freshness/visibility/permission/expiry and capacity arbitration are still BLOCKED.

## Secure developer preparation and acceptance

Run in the main folder, without secret command arguments:

```powershell
./dev_tools/check_eos_prerequisites.ps1
./dev_tools/check_eos_prerequisites.ps1 -RequireLive # exit2 by design at current gate
./dev_tools/validate.ps1 -Godot C:/Godot/Godot.exe
```

Populate the PV_EOS_* names from M19_BLOCKERS through a private process/runner environment,
not chat, CLI flags, committed .env/resource, screenshots, artifacts or shell history. The
script prints names/booleans only and never extracts the supplied SDK. ZIP entry-name hints
are not exact-version/legal review. Provision the legitimately obtained full SDK1.19.1.2
outside the checkout, retain exact hash/notices and obtain explicit distributable-file review.
Do not substitute the GitHub wrapper release for that full SDK package.

No secret-bearing workflow is created while repository policy is absent. Proposed protected
GitHub environment `eos-acceptance`: required reviewer, no self-approval, allowed reviewed
refs only, protected/manual workflow_dispatch on trusted dev, checkout immutable reviewed
SHA, least-privilege contents:read, bounded owned-process cleanup. Bind PV_EOS_PRODUCT_ID,
PV_EOS_SANDBOX_ID, PV_EOS_DEPLOYMENT_ID, PV_EOS_CLIENT_ID, PV_EOS_CLIENT_SECRET,
PV_EOS_DEV_AUTH_ENDPOINT and NAME_A/B only inside that protected job. Provision private
SDK file locally and point PV_EOS_SDK_ARCHIVE at it. Never bind secrets to pull_request or
pull_request_target checkout code. Do not upload stdout/stderr from live SDK processes;
generate a separate allowlisted result/timing/count report. These are proposed controls,
not a claim that GitHub environment/secrets/runners have been configured.

After prerequisite and native review, implement the missing EOSG executor and privacy decision,
then run two exported Windows processes with distinct authorized Epic identities using Dev Auth.
Prove Auth→Connect, code discovery/private join,2 members and third-account rejection, actual
EOS P2P carrying handshake/input/snapshot/events, M16 gameplay/Finish/results and cleanup.
Two processes on one machine are allowed if traffic traverses EOS/Internet; record NAT/topology,
never localhost ENet as acceptance. Linux EOS exports and separate SteamOS remain their own
cells. There is deliberately **no live acceptance launch command yet**; inventing one here
would imply a missing executor exists. Stop again for review after adding and proving it.
