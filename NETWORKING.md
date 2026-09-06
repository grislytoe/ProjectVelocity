# Networking

M0 status: no networking implementation or SDK dependency.

`BuildInfo.NETWORK_PROTOCOL_VERSION` is the source-controlled network compatibility identity, initially `1` for the pre-network project. It is independent of the game version (`VERSION`), build number (`BUILD_NUMBER`) and build channel (`channel()`). Keep it stable across compatible builds; increment it when incompatible wire formats, message semantics or synchronization contracts are introduced. Future connection handshakes must compare this value and reject unsupported versions before gameplay. M0 only defines the identity; no handshake or networking is implemented yet.

Approved future model: two-player host-authoritative listen server, input commands, guest prediction and reconciliation, remote interpolation. Physics 60 Hz; initial snapshots 20-30 Hz with configurable rates. Reconstruct animation/VFX from gameplay state/events. Standalone online must not depend on Steam.

EOSG 2.3.0 is a candidate requiring explicit compatibility smoke tests before production integration. Service contracts/adapters belong in platform_services; simulation must remain transport-independent. See docs/MASTER_SPECIFICATION.txt for the complete requirements.
