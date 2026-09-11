# Transport and synchronized simulation

M16 extends M15: the layer owns transport-independent host simulation, validated packet values, prediction/replay,
interpolation, events and clock. LocalENetTransport alone implements the loopback adapter.
Start `local_network.tscn` in two processes using the commands in ../NETWORKING.md.
No online service, persistent identity, Solo save or SDK belongs in this layer.

RaceBaseline carries durable round/lifecycle progress; pooled slots carry generations.
NetworkRaceFixture is a debug-only local acceptance driver, never a production input source.
