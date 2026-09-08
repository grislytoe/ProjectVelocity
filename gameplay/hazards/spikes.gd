class_name Spikes
extends CycleHazard

@export var config: SpikeConfig = preload("res://gameplay/hazards/default_spikes.tres")
var sensor: Area2D


func _ready() -> void:
	spike_visual = true
	if config == null:
		super._ready()
		return
	tuning = config
	permanent = config.mode == SpikeConfig.Mode.STATIC
	triggered_mode = config.mode == SpikeConfig.Mode.TRIGGER
	trigger_requested = config.initially_triggered
	super._ready()
	if triggered_mode and config.trigger_on_player_overlap and config.validate():
		sensor = Area2D.new()
		sensor.collision_layer = 0
		sensor.collision_mask = 2
		sensor.position = config.trigger_offset
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = config.trigger_size
		collision.shape = shape
		sensor.add_child(collision)
		add_child(sensor)


func _physics_process(delta: float) -> void:
	if sensor != null:
		var occupied: bool = false
		for body: Node2D in sensor.get_overlapping_bodies():
			if body is PlayerController and not (body as PlayerController).motor.machine.locked():
				occupied = true
		set_trigger(occupied)
	super._physics_process(delta)


func _draw() -> void:
	super._draw()
	if sensor != null:
		draw_rect(Rect2(config.trigger_offset - config.trigger_size / 2, config.trigger_size),
			Color(0.3, 0.8, 1, 0.5), false, 2)
