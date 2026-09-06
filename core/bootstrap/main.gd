extends Control
## Placeholder composition root; gameplay and services are added in later milestones.

@onready var build_label: Label = %BuildLabel
@onready var _logger: ProjectLogger = get_node("/root/AppLogger")


func _ready() -> void:
	build_label.text = BuildInfo.label()
	build_label.visible = BuildInfo.is_development() or OS.has_feature("staging")
	_logger.info("ProjectVelocity %s started" % BuildInfo.label(), "bootstrap")
	if OS.get_cmdline_user_args().has("--smoke-test"):
		_run_smoke_test.call_deferred()


func _run_smoke_test() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	if Engine.physics_ticks_per_second != 60:
		_logger.error("Expected 60 Hz physics", "bootstrap")
		get_tree().quit(1)
		return
	print("PROJECTVELOCITY_BOOT_OK")
	get_tree().quit(0)
