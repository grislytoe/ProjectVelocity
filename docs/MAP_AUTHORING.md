# M13 map authoring and inspection

1. Work in C:/Godot Projects/ProjectVelocity. Open a small reusable section scene;
   keep its Node2D root at identity. Use the existing M8/M9 module scenes and configs.
2. Set MapSectionDefinition.scene_path. Add local Entrance/Exit Marker2D nodes at
   the appropriate left/right floor-top edges. Declare major rectangle collision
   paths, using your map's grid. Preserve finer hazard/checkpoint/respawn placement.
3. In MapDefinition, add ordered MapSectionPlacement resources with unique instance
   IDs, translations on the grid and explicit next_id links. Reuse one definition
   resource for repeated geometry; do not give different definitions the same ID.
4. Author Start, Finish and checkpoint MapPoint references. Set strict_order and
   mandatory flags. Start/checkpoint respawns need the player's full capsule clearance,
   stationary support and no fatal overlap. Use M7 safety checks, not visual guesses.
5. Fill identity, RU/EN translation keys, preview, duration/par and death bounds. Add
   approved official entries explicitly to MapCatalog. No folder scan/Workshop exists.
6. Run import, MapValidator.inspect and the full validator. After reviewing intended
   gameplay changes, increment official map version when publishing a new revision,
   then run `./dev_tools/check_trial_hash.ps1 -Update -Godot C:/Godot/Godot.exe`.
   Inspect both generated code manifest and declared map checksum; do not bypass stale
   hash checks. New code/configs must be covered by the manifest's dependency policy.
7. Play actual routes. Structural success is not a physical traversability proof.
   The current automated motor-driven run covers Training Circuit's direct route.

F6 scene: `res://dev_tools/map_framework.tscn`. Keys:
1 Training Circuit; 2 valid single section; 3 seam gap; 4 missing respawn anchor;
5 checksum mismatch. Rejected definitions activate no gameplay subtree. Cyan rings
mark entrances, gold rings exits and green dots respawns. Grid is 20 world pixels for
these examples. The overview freezes gameplay and uses a separate developer camera.
It writes no save. `-- --capture` saves ignored builds/m13-map-framework-1.png through -5.png and exits.

`tests/map_framework_test.gd` generates additional temporary scene mutations under
ignored builds/m13-fixtures, with saves in unique OS-cache folders. It covers null/
empty maps, missing refs/dependencies/configs, unsupported transforms, bad seams/grid,
IDs/links/route metadata, deterministic canonicalization, unsafe respawns and cleanup.
The fixture generator must not modify the cached catalog: use deep Resource copies.

The production Level Editor stays In Development. No final map, runtime streaming,
network transport, Workshop, digital signatures or M14 work is included.
