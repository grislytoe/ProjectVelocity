# Map format

Not implemented in M0. map_data/ reserves ownership.

Future MapDefinition includes stable map_id, map_version, translated name/description keys, scene, preview, official/custom type, difficulty, expected duration, par time, mandatory checkpoint metadata and checksum. Compare id/version/checksum before online play. Use modular sections with entrance/exit anchors and seam validation; no streaming or digital signatures in the initial implementation.

## M7 course contract

Until MapDefinition is introduced, map composition supplies ordered StringName IDs, a mandatory subset and strict_order (default true) to each player's CheckpointProgress. Assign fixed Marker2D respawn anchors with capsule clearance, stationary floor support and no fatal-layer overlap. Unknown mandatory IDs or duplicate course IDs fail validation. Full MapDefinition/checksum/sections remain later scope. See CHECKPOINTS_AND_LIFECYCLE.md.
