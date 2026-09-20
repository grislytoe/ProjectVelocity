# M19 EOS Lobby / P2P — BLOCKED delivery

**Verdict: BLOCKED. M19 acceptance is not met.** Safe project policy and regression
tests are delivered; no configured EOS platform, Auth/Connect, native Lobby/P2P adapter,
two-client Internet session, or EOS-bearing export is claimed. Production Online remains
unavailable. This is not a completed milestone disguised as a mock success.

Authorized after M18 PR19 was merged into dev at
`934d88701b08d7f6a67e8bd8d842660c11e8f1d8`. Base CI
[34812285568](https://github.com/grislytoe/ProjectVelocity/actions/runs/34812285568)
completed successfully. Main folder only: `C:/Godot Projects/ProjectVelocity`.
Branch `feature/m19-eos-lobby-p2p`. Build **0.19.0-dev /25**, **protocol3/wire2**,
save schema5. EOSG **2.3.0**, exact commit
`e84320567a3a17d305478f5796707e69d2bdac4f`, SDK **1.19.1.2-53289219** unchanged.
`project.godot` remains user-owned, excluded, SHA256
`5b9713aca5045dd697ea09df21e9de658283b782b3b0c8f2cc540539fabb65ac`.

## Prerequisites checked on this task's Windows process

| Name / evidence | Present | Meaning |
|---|---|---|
| PV_EOS_PRODUCT_ID | false | Configuration unavailable to this process |
| PV_EOS_SANDBOX_ID | false | Same |
| PV_EOS_DEPLOYMENT_ID | false | Same |
| PV_EOS_CLIENT_ID | false | Same |
| PV_EOS_CLIENT_SECRET | false | Same; no value requested in chat |
| PV_EOS_DEV_AUTH_ENDPOINT | false | Tool reachability not tested |
| PV_EOS_DEV_AUTH_NAME_A | false | No first authorized test identity provisioned here |
| PV_EOS_DEV_AUTH_NAME_B | false | No second authorized test identity provisioned here |
| PV_EOS_SDK_ARCHIVE | false | Full licensed exact SDK/notices unavailable here |
| Local Windows and Linux debug/release templates | false / false | No local standalone export acceptance |
| Godot4.7.2 Windows executable | true | Ordinary editor/headless/renderer tests possible |
| Pinned M18 Windows/Linux release ZIPs | true | Prior candidate evaluation assets, not full Epic SDK |
| Linux CI | configured | Ubuntu native gate is not Linux export or SteamOS |
| Representative SteamOS runner | unprovided | No SteamOS evidence |

No credential store, private account, or arbitrary SDK directory was searched. Absent here
does not mean absent from the developer's possession. Presence checking never establishes
valid credentials, distinct valid PUIDs, consent, client policy, exact version, or licensing.

## Additional source-review boundary

The pinned [peer source](https://github.com/3ddelano/epic-online-services-godot/blob/e84320567a3a17d305478f5796707e69d2bdac4f/src/eosg_multiplayer_peer.cpp#L686)
reads native packet fields before an apparent minimum-header-size check. For stored game
packets it looks up the header's peer ID, then queues that ID without carrying the service
sender PUID to GDScript. The pinned
[mediator](https://github.com/3ddelano/epic-online-services-godot/blob/e84320567a3a17d305478f5796707e69d2bdac4f/src/eosg_packet_peer_mediator.cpp#L98)
also inspects the first byte before an apparent nonempty check. These are **source findings**,
not a reproduced crash or proven live exploit. Native malformed-input/membership validation
must be reviewed and reproduced with owned test clients before exposing it to Internet input.
Project-side codec checks run too late to prove native memory safety or restore erased
authenticated sender provenance. No candidate patch, fork or substitute transport is supplied.

Pinned public API inspected: `create_server(socket_id)`, `create_client(socket_id, remote_user_id)`,
`set_auto_accept_connection_requests(false)`, `get_all_connection_requests`,
`accept_connection_request`, `deny_connection_request`, `get_peer_user_id`,
`get_packet_channel`, `get_packet_mode`, `get_packet`, `put_packet`, `poll`, `close`.
There is no invented public `IEOS.send_packet`/`receive_packet` adapter. Native methods
in the source are not automatically GDScript-callable. Application channel mapping differs
from raw EOS channel mapping; it remains a live validation cell, not a guessed mapping.

Developer review options: (1) retain blocked candidate and obtain upstream clarification/
controlled evidence with the exact source; (2) separately authorize an exact minimal native
patch after reviewing its diff and provenance implications. Option1 is the current path.
Changing dependency identity requires a new explicit decision. Neither option is silently applied.

M18 concerns persist: full plugin adds10 autoloads; export hook indexes `features[2]`;
disable omits HSessions; global shutdown prevents reinitialization in the same process.
High-level HAuth also logs persistent identities and offers automatic linking/device flows.
Do not enable those helpers unchanged as a secure application login flow. A project adapter
must use the inspected low-level contract with redacted handling, not copy helper logging.

Private-code discovery also needs an explicit permission/visibility decision. Pinned
`EOS.Lobby.LobbyPermissionLevel` exposes PublicAdvertised/JoinViaPresence/InviteOnly;
HLobbies describes attribute search as public-lobby search. We do **not** assume that
InviteOnly is discoverable by a public attribute, or label PublicAdvertised as access-private.
The [Epic lobby documentation](https://dev.epicgames.com/docs/epic-online-services/multiplayer/lobbies-and-sessions/lobby-interface)
and [security considerations](https://dev.epicgames.com/docs/epic-online-services/multiplayer/lobbies-and-sessions/security-considerations)
need verification against the full SDK and a real private-code experiment (their client-rendered
bodies were unavailable to text retrieval here). Do not substitute a directory server/REST
service, silently publish public rooms, or claim the six-character code is authorization.

## Delivered versus blocked matrix

| Cell | Evidence category / current boundary |
|---|---|
| Join-code generation/normalization/collision retry | Non-live project unit test |
| Metadata compatibility/capacity/result resolution | Non-live detached service-row test |
| Identity operation order/timeout/cancel/link-required/shutdown | Non-live state policy; no native lifecycle/auth executor |
| Lobby create/search/join admission/timeout/late results | Non-live coordinator; no EOS handles or calls |
| P2P framing/membership/socket/epoch/channel/size/queue/cleanup | Non-live authenticated-envelope fixture; no native safety proof |
| M11 unavailable RU/EN/Back focus | Ordinary real GUI test; Create/Join disabled |
| Configured platform; Auth account → distinct Connect PUIDs | BLOCKED |
| Real private lobby publish/search/join and third-account rejection | BLOCKED |
| Native P2P carrying M15 handshake and M16 gameplay | BLOCKED |
| Live Create/Code/Copy/Join/cancel/ready/start/controller code entry | BLOCKED; not simulated in production UI |
| Live disconnect/reconnect/logout/relogin/native cleanup | BLOCKED |
| Windows/Linux EOS-bearing standalone exports | BLOCKED |
| SteamOS and live Internet acceptance | BLOCKED |

See [M19 validation](M19_VALIDATION.md) for actual regression results, and
[integration contract](M19_EOS_INTEGRATION.md) for policy limits and developer commands.
Commit/PR and exact head CI are reported at delivery. No automatic merge or M20.
