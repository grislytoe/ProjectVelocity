# Transport and synchronized simulation

M15 owns transport-independent host simulation, validated packet values, prediction/replay,
interpolation, events and clock. LocalENetTransport alone implements the loopback adapter.
Start `local_network.tscn` in two processes using the commands in ../NETWORKING.md.
No online service, persistent identity, Solo save or SDK belongs in this layer.
