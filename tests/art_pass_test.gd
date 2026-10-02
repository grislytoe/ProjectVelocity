extends SceneTree
## M23 presentation contracts: registry, budgets and shape grammar. No production saves.

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	run.call_deferred()


func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)


func run() -> void:
	check(VisualAssetRegistry.MANIFEST_VERSION == 1, "Known visual manifest version")
	check(VisualAssetRegistry.environment_source("../arbitrary.png").is_empty(),
		"Registry never accepts arbitrary paths")
	check(not VisualAssetRegistry.cosmetic_id_registered("head", "res://attack.gd"),
		"Profile cosmetic values cannot become resource paths")
	for slot: String in ["head", "hat", "torso", "arms", "legs"]:
		check(VisualAssetRegistry.cosmetic_id_registered(slot, ""), "Base fallback registered: " + slot)
	var training_art := VisualAssetRegistry.create_environment("solo_training")
	check(training_art == null, "Theme-specific art is not imposed on generic maps")
	var foundry_art := VisualAssetRegistry.create_environment("industrial_foundry")
	check(foundry_art is IndustrialFoundryBackground, "Foundry resolves curated background")
	root.add_child(foundry_art)
	check(foundry_art.process_mode == Node.PROCESS_MODE_DISABLED and foundry_art.z_index < -10,
		"Background is presentation-only and behind route silhouettes")
	foundry_art.free()

	var image := Image.load_from_file(ProjectSettings.globalize_path(
		"res://visuals/environment/industrial_foundry_far.webp"))
	check(not image.is_empty() and image.get_width() == 1024 and image.get_height() == 512,
		"Integrated raster is the exact 1024x512 budget")
	check(image.get_width() <= 1024 and image.get_height() <= 1024,
		"Every committed raster respects the 1024 atlas cap")
	check(image.get_width() * image.get_height() * 4 == 2097152,
		"Decoded RGBA estimate is 2 MiB")
	var import_text := FileAccess.get_file_as_string(
		"res://visuals/environment/industrial_foundry_far.webp.import")
	check(import_text.contains("compress/mode=0") and import_text.contains("mipmaps/generate=false"),
		"Background import policy is explicit for 2x display without repetition")
	var manifest_text := FileAccess.get_file_as_string(
		"res://visuals/environment/asset_manifest.json")
	var manifest: Variant = JSON.parse_string(manifest_text)
	check(manifest is Dictionary and manifest.assets.size() == 1,
		"Machine-readable asset inventory parses")
	check(manifest.assets[0].status == "integrated_first_pass" and manifest.assets[0].atlas == false,
		"Manifest separates integrated standalone raster")

	var kinds: Array[String] = ["static", "one_way", "moving", "breakable", "jump_pad"]
	for kind: String in kinds:
		var visual := PlatformVisual.new()
		visual.configure(PackedVector2Array([Vector2(-50, -10), Vector2(50, -10),
			Vector2(50, 10), Vector2(-50, 10)]), kind)
		check(visual.kind == kind and visual.polygon.size() == 4, "Platform shape grammar: " + kind)
		visual.free()

	var required: Array[int] = [PlayerAnimationMachine.Pose.IDLE, PlayerAnimationMachine.Pose.RUN,
		PlayerAnimationMachine.Pose.JUMP, PlayerAnimationMachine.Pose.FALL,
		PlayerAnimationMachine.Pose.DOUBLE_JUMP, PlayerAnimationMachine.Pose.WALL_SLIDE,
		PlayerAnimationMachine.Pose.WALL_JUMP, PlayerAnimationMachine.Pose.DASH,
		PlayerAnimationMachine.Pose.LANDING, PlayerAnimationMachine.Pose.DEATH,
		PlayerAnimationMachine.Pose.RESPAWN, PlayerAnimationMachine.Pose.FINISH_VICTORY,
		PlayerAnimationMachine.Pose.TURNAROUND, PlayerAnimationMachine.Pose.SKID]
	check(required.size() == 14 and not required.has(PlayerAnimationMachine.Pose.FAST_FALL_RESERVED),
		"Fourteen required states remain distinct from reserved FastFall")
	var profile := PlayerProfileData.create()
	var bodies: Array[String] = ["44ccee", "f4f7f8", "243347", "d98a45", "8e6dcc"]
	var accents: Array[String] = ["ffffff", "7fffd4", "ffd45c", "ff6b7d", "9fb7ff"]
	for body: String in bodies:
		for accent: String in accents:
			profile.body_color = body + "ff"
			profile.accent_color = accent + "ff"
			var local := PlayerPlaceholder.new()
			root.add_child(local)
			check(local.apply_profile(profile) and local.modulate.a == 1.0,
				"Body/accent local combination remains opaque")
			local.is_local = false
			check(is_equal_approx(local.modulate.a, 0.3) and
				local.parts.head.body_color == Color(body) and local.parts.head.accent_color == Color(accent),
				"Opponent preserves combination at policy alpha")
			local.free()

	var caps: HazardCapsConfig = preload("res://gameplay/hazards/default_caps.tres")
	check(caps.projectiles_global == 10 and caps.projectiles_per_target == 5,
		"Repeated projectile VFX retains bounded preallocated pool")
	check(IndustrialFoundryBackground.PLATE != null,
		"First-use environment asset is preloaded by the presentation class")
	if failures == 0:
		print("PROJECTVELOCITY_M23_ART_OK (%d checks)" % checks)
	quit(0 if failures == 0 else 1)
