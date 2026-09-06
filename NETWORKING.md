# Networking

M0 status: no networking implementation or SDK dependency.

Approved future model: two-player host-authoritative listen server, input commands, guest prediction and reconciliation, remote interpolation. Physics 60 Hz; initial snapshots 20-30 Hz with configurable rates. Reconstruct animation/VFX from gameplay state/events. Standalone online must not depend on Steam.

EOSG 2.3.0 is a candidate requiring explicit compatibility smoke tests before production integration. Service contracts/adapters belong in platform_services; simulation must remain transport-independent. See docs/MASTER_SPECIFICATION.txt for the complete requirements.
