class_name MapPoint
extends Resource
## A reference to a section-local Marker2D. Trigger size is in world pixels.
## Start/checkpoint respawns are separate anchors and pass existing physics safety checks.

@export var point_id: StringName
@export var section_id: StringName
@export var anchor: NodePath
@export var respawn_anchor: NodePath
@export var trigger_size: Vector2 = Vector2(32, 450)
@export var mandatory: bool = true
