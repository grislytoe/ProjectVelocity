class_name MapSectionPlacement
extends Resource
## Ordered linear chain. Reuse definitions with unique instance IDs.
## M13 supports translation only: gravity-bound authored platforms must stay upright.

@export var instance_id: StringName
@export var section: MapSectionDefinition
@export var transform: Transform2D = Transform2D.IDENTITY
@export var next_id: StringName
