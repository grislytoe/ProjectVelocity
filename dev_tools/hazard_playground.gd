class_name HazardPlayground
extends Node2D
## Station-scoped composition; only the local actor owns physical InputLayer.

var authority: HazardWorld
var modules: Array[Node2D] = []
var turrets: Array[Turret] = []
var opponent: PlayerController
var local_life: PlayerLifecycle


func populate(id: String, actor: PlayerController, spawn: Vector2) -> void:
	local_life = PlayerLifecycle.new()
	add_child(local_life)
	local_life.bind(actor, Vector2(spawn.x, 466))
	match id:
		"DEATH_ZONE":
			var zone := preload("res://gameplay/race/death_zone.tscn").instantiate() as DeathZone
			zone.position = Vector2(450, 488)
			add_child(zone)
			modules.append(zone)
		"SPIKES":
			for mode: int in SpikeConfig.Mode.values():
				var spikes := preload("res://gameplay/hazards/spikes.tscn").instantiate() as Spikes
				spikes.config = SpikeConfig.new()
				spikes.config.mode = mode as SpikeConfig.Mode
				spikes.config.trigger_on_player_overlap = mode == SpikeConfig.Mode.TRIGGER
				spikes.position = Vector2(420 + mode * 420, 488)
				add_child(spikes)
				modules.append(spikes)
		"SAWS":
			for moving: bool in [false, true]:
				var saw := preload("res://gameplay/hazards/saw.tscn").instantiate() as Saw
				saw.config = SawConfig.new()
				saw.config.moving = moving
				saw.position = Vector2(900 if moving else 440, 440)
				add_child(saw)
				modules.append(saw)
		"LASERS":
			for mode: int in LaserConfig.Mode.values():
				var laser := preload("res://gameplay/hazards/laser.tscn").instantiate() as Laser
				laser.config = LaserConfig.new()
				laser.config.mode = mode as LaserConfig.Mode
				laser.config.size.y = 180
				laser.position = Vector2(440 + mode * 500, 410)
				add_child(laser)
				modules.append(laser)
		"TURRETS", "HAZARD_CAPS":
			authority = HazardWorld.new()
			add_child(authority)
			authority.register_player(&"local", actor)
			opponent = preload("res://gameplay/player/player.tscn").instantiate() as PlayerController
			opponent.position = Vector2(800, 450)
			add_child(opponent)
			opponent.presentation.is_local = false
			# A neutral frame is the offline second actor's independent input source.
			authority.register_player(&"test_player", opponent)
			var life := PlayerLifecycle.new()
			add_child(life)
			life.bind(opponent, Vector2(800, 466))
			for index: int in (4 if id == "HAZARD_CAPS" else 1):
				var turret := preload("res://gameplay/hazards/turret.tscn").instantiate() as Turret
				turret.position = Vector2(500 + index * 180, 150)
				turret.config = TurretConfig.new()
				if id == "HAZARD_CAPS":
					# Slow rounds + short cadence make both projectile caps observable.
					turret.config.projectile_speed = 135
					turret.config.cooldown = 0.05
					turret.config.minimum_cooldown = 0.1
					turret.config.telegraph_duration = 0.25
				turret.bind(authority, [&"local", &"test_player"])
				add_child(turret)
				turrets.append(turret)
				modules.append(turret)


func diagnostics_text() -> String:
	var result: String = ""
	for module: Node2D in modules:
		if module is CycleHazard:
			result += "%s:%s  " % ["Spikes" if module is Spikes else "Laser", CycleHazard.State.keys()[module.state]]
		elif module is Saw:
			result += "Saw %.0f/%.0f  " % [module.position.x, module.position.y]
	if authority != null:
		result += "Pool %d/%d | local %d/%d test %d/%d | skipped %d\n" % [
			authority.active_count(), authority.projectiles.size(), authority.active_count(&"local"),
			authority.caps.projectiles_per_target, authority.active_count(&"test_player"),
			authority.caps.projectiles_per_target, authority.skipped_shots]
		for turret: Turret in turrets:
			for channel: TurretChannel in turret.channels:
				result += "%s:%s(%d) " % [channel.target_player_id,
					TurretChannel.State.keys()[channel.state], channel.remaining_ticks]
			result += "\n"
		result += "Engagements local %d / test %d (cap %d each)" % [
			authority.engagements[&"local"].size(), authority.engagements[&"test_player"].size(),
			authority.caps.engaging_turrets_per_target]
	return result
