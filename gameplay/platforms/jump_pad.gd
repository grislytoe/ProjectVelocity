class_name JumpPad
extends StaticBody2D
## Solid top-contact pad; controller/motor own the launch, including Dash interruption.

@export var config: JumpPadConfig = preload("res://gameplay/platforms/default_jump_pad.tres")


func _ready() -> void:
	add_to_group("unsafe_respawn_support")
	if config == null or not config.validate():
		push_error("Invalid jump pad config")
		return
	PlatformGeometry.build(self, config)
	var arrow := Line2D.new()
	arrow.points = PackedVector2Array([Vector2(0, -6), Vector2(0, -6) + config.direction.normalized() * 45])
	arrow.width = 5
	arrow.default_color = Color("ffe275")
	add_child(arrow)


func on_player_contact(player: PlayerController, normal: Vector2) -> void:
	if normal.dot(Vector2.UP) >= 0.7:
		player.launch_from_platform(config.direction.normalized().rotated(global_rotation) * config.force)
