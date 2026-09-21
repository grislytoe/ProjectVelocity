# Transport and synchronized series simulation

M21 extends M15/M16: the layer owns transport-independent host simulation, validated packet values, prediction/replay,
interpolation, events and clock. LocalENetTransport alone implements the loopback adapter.
Start `local_network.tscn` in two processes using the commands in ../NETWORKING.md.
No online service, persistent identity, Solo save or SDK belongs in this layer.

RaceBaseline carries durable round/lifecycle progress and OnlineSeries carries immutable
settings, generations, loaded/Ready state, results, score and final outcome. Pooled slots carry generations.
NetworkRaceFixture is a debug-only local acceptance driver, never a production input source.

M17 profiles, measured telemetry, runtime controls and exact commands: see ../NETWORKING.md
and ../docs/M17_VALIDATION.md. M21 uses protocol4/wire3; host gameplay authority is unchanged.
