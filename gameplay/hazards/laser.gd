class_name Laser
extends CycleHazard

@export var config: LaserConfig = preload("res://gameplay/hazards/default_laser.tres")


func _ready() -> void:
	if config == null:
		super._ready()
		return
	tuning = config
	permanent = config.mode == LaserConfig.Mode.PERMANENT
	super._ready()
