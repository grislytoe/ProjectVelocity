# Map format — M13 / PV-MAP-1

`map_data/training_circuit.tres` is the production catalog entry used by Map Select,
SoloTrial, checkpoint progress and TrialRecords. Stable ID `solo_training`, map version
**3**. Training Circuit remains the short M10 module demonstration, not the final map.
Build 0.14.0-dev /19; save schema 5; protocol 1.

## Resources and units

- MapDefinition: stable nonempty `map_id` (no colon, the record-key separator), positive
  integer `map_version`, name/description/difficulty translation keys, `scene_path`,
  optional Texture2D `preview`, official/custom `map_type`, positive expected duration
  in seconds, positive `par_time_ticks` at 60 Hz, grid dimensions, ordered section
  placements, Start/Finish/checkpoint metadata, strict_order, fall DeathZone bounds,
  declared_checksum. Preview/name/description/difficulty/duration are presentation.
- MapSectionDefinition: stable section_id, packed scene path, entrance/exit Marker2D
  paths and major_geometry CollisionShape2D paths. Reuse one definition Resource for
  multiple placements; distinct definitions cannot claim the same section_id.
- MapSectionPlacement: unique instance_id, section Resource, Transform2D, next_id.
  Array order is the linear route; next_id references exactly the following placement.
  The last next_id is empty. Loops, branches and missing links are rejected in M13.
- MapPoint: unique point_id, section instance ID, local trigger Marker2D path,
  separate respawn Marker2D path for Start/checkpoints, trigger_size in pixels,
  mandatory flag for checkpoints. Start/Finish roles come from their fields.

Coordinates are Godot 2D world pixels, +X right, +Y down. The assembly host and section scenes have identity root transforms. Top-level nodes
are rejected inside sections so anchors cannot escape their declared coordinate space. M13 supports finite translations only for section placements and
anchor frames: unit X/Y basis, no scale, reflection, rotation or skew. This is the
initial supported transform contract for gravity-bound modules, not a numeric rule
from the master specification. Local nested Marker2D transforms are accumulated.
The design can add a new transform/seam contract later without changing ownership.

Grid size is configurable per map: the master spec prescribes no numeric cell or
section size. Training uses 20×20 px cells and the original 1400 px sections. Origins,
entrance/exit positions and major floor rectangle boundaries lie on that lattice.
Hazards, props, triggers and respawns permit finer positions (e.g. y=566 respawns).

## Structural rules and safety

M13's supported seam is an upright horizontal floor connection: entrance marks the
left top edge of a declared stationary rectangular floor collider; exit marks its
right top edge. Consecutive exit/entrance positions coincide in map space. The floor
rectangles cannot overlap with positive area; touching edges are allowed. Different
entry/exit heights within a section are possible with different floor pieces.
Only declared **major** collision footprints are grid/seam checked; slopes, optional
platforms, hazards and decoration may use finer geometry. This contract does not
assert player clearance, navigation, jump reachability or completion of every route.

All major geometry paths must resolve to unique enabled RectangleShape2D colliders
under stationary StaticBody2D support on the world collision layer. Their transforms
are translation-only. Moving/temporary supports cannot establish a safe respawn.
Start belongs to the first section; Finish to the last. The checkpoint sequence follows
section order. Within-section traversal order is authored, not inferred from X position.
IDs and trigger markers are unique, point dimensions finite and positive, references
local (no absolute paths, `..` or property subnames). Null/empty entries fail validation.
Scene dependencies must be available packaged res:// resources. Module config validators
run on detached scene instances. Non-finite/singular node transforms and embedded
player/lifecycle/Finish/checkpoint/pool authorities are rejected.

MapValidator produces structured code/location/detail diagnostics for identity,
metadata, grid, sections/section, id, link, scene/dependency, transform, geometry,
overlap, anchor/seam_support/seam, point/reference/order, bounds/config/authority and
checksum errors. Solo adds respawn errors after physics registration. Player-facing
RU/EN errors are MAP_INVALID or MAP_CHECKSUM_ERROR; developer details stay separate.
Malformed scripts/scenes can additionally emit Godot import/parser diagnostics; authoring
requires a clean import/parser pass. Definitions are local trusted project content;
loading arbitrary executable scripts is not a sandbox or a Workshop security boundary.

SoloTrial validates before adding a course, then SoloCourse constructs its owned
MapAssembly, one player/lifecycle, triggers, one HazardWorld and camera. Turrets bind
to the owned world before entering the tree. On the first physics step, before any
control, every Start/checkpoint respawn is checked by M7 RespawnSafety (capsule
clearance, stationary floor and fatal exclusion). Failure frees course and barrier
and enters the localized ERROR screen. Retry failures also destroy the previous
subtree. StartBarrier/PlayerLifecycle remain GO/Finish/progress authorities.
Respawn safety is checked again during ordinary checkpoint activation and respawn.
Assembly/unload happen outside query flushing, with no streaming or global callbacks.

## Identity and canonical representation

`MapDefinition.checksum()` is the only production map checksum. PV-MAP-1 is SHA-256
of a tagged, length-delimited UTF-8 representation with explicit map ID/version/type,
par ticks, grid, fall bounds, strict order, ordered placements/links/section IDs,
major geometry paths, route points and the semantic scene/resource graph.
Arrays and node order are significant; dictionaries/properties and signal names are sorted.
Persistent connections are collected from resolved nodes, including nested/inherited
scenes. Target paths, methods, flags, bound/unbound arguments and connection order within
each signal participate in identity.
Booleans, integers, strings, vectors, transforms, rectangles, colors and packed arrays
have type tags; finite floating values use little-endian IEEE754 double bytes with
negative zero normalized. Strings are exact UTF-8; translations/locales are not hashed.
Unsupported or cyclic resource content fails closed.

Scenes are instantiated **detached**, without _ready or physics, to resolve inheritance
and default properties before canonicalizing stored properties. Stored Resource
properties are recursively canonicalized. File formatting, ext/subresource IDs, UIDs,
editor_description, metadata/_editor*, resource_name, scene_file_path and machine-local
paths are excluded. Node names/paths are significant references. Relocating equivalent
section scene files preserves identity; changing geometry/module tuning/point metadata
changes it. Presentation properties inside gameplay scenes/resources are conservatively
included; the map's preview/translations/difficulty/expected duration are excluded.

MapCodeManifest is a generated, ordinal-path-sorted code bundle digest covering all .gd
in gameplay, map_data (except the manifest), core/input, core/camera and visuals.
UTF-8 source uses normalized LF. Comments and unrelated code in those folders are
conservatively significant. DATA_PATHS lists all .tscn/.tres in gameplay, core/input,
core/camera and visuals so implicit default/preloaded configs also participate via
semantic hashing. Section scenes are added through the map's references. No timestamps,
caches, absolute paths or translated strings enter the digest. No dynamic external
content/code dependencies are supported; new modules must join the verified bundle.

`dev_tools/check_trial_hash.ps1 -Update -Godot C:/Godot/Godot.exe` regenerates that code
manifest and calls the **same Godot checksum implementation** to bake the official
checksum. Without -Update it rejects stale code/data identities. Run import first
for new classes/assets. CI imports, parses, runs tests and compares editor versus compiled
Windows PCK map hashes during isolated boot/assembly. Exported scripts use the baked
code identity; CI verifies its source. A runtime checksum is not a signature, an
anti-cheat proof, or protection from a malicious client replacing code and metadata.

`compatible_with` compares valid declared/recomputed checksum plus exact ID/version.
It is a local helper for future consumers, with no network transport or online check.

## Records and compatibility

M12 records for solo_training version 1 retain their original key/checksum and remain
on disk. M13 uses version 2 and PV-MAP-1; old PBs are never silently promoted or compared.
TrialMapDefinition is only a source-compatible adapter to MapCatalog.training, with no
independent fields or legacy hash implementation. Save schema stays **5**: UUID,
onboarding, settings, cosmetics and records are untouched by map migration.

Trial records store actual activated checkpoint IDs and monotonic timestamps. All IDs
must be a valid route under the definition, with mandatory checkpoints present. Strict
maps retain M7 ordered activation; nonstrict maps may activate out of order. Live/result
checkpoint deltas match IDs in the best complete run. Total PB compares valid finishes
of this map identity; segment minima merge only when both complete routes have identical
ID order. A faster different route establishes its own segment minima; a slower different
route leaves the existing PB/minima unchanged. No schema migration or duplicate runtime
progress counter is introduced. See SAVE_FORMAT.md and TIME_TRIAL.md.

## M14 catalog and camera additions

Foundry Run (industrial_foundry version 2) is a separate official eight-section map.
MapDefinition now carries optional CameraBounds and CameraZone resources; they are
validated and included in PV-MAP-1. SoloCourse injects them into the M5 camera.
The conservative shared code/format identity update publishes Training version 3;
version 1/2 PB keys remain untouched on disk. check_trial_hash.ps1 bakes both maps.
See docs/M14_INDUSTRIAL_TRACK.md for physical traversal evidence and human review.
