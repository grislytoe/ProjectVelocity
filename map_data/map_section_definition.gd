class_name MapSectionDefinition
extends Resource
## Scene-local coordinates, pixels; entrance/exit are Marker2D paths in this scene.

@export var section_id: StringName
@export var scene_path: String = ""
@export var entrance: NodePath = ^"Entrance"
@export var exit: NodePath = ^"Exit"
## Rectangle CollisionShape2D paths on stationary StaticBody2D: major floor footprints.
## Other geometry/hazards/decor may use finer placement. Not a traversal proof.
@export var major_geometry: Array[NodePath] = []
