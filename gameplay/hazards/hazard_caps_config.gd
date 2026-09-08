class_name HazardCapsConfig
extends Resource

@export_range(1, 100) var projectiles_per_target: int = 5
@export_range(1, 200) var projectiles_global: int = 10
@export_range(1, 32) var engaging_turrets_per_target: int = 3


func validate() -> bool:
	return projectiles_per_target > 0 and projectiles_per_target <= 100 \
		and projectiles_global > 0 and projectiles_global <= 200 \
		and engaging_turrets_per_target > 0 and engaging_turrets_per_target <= 32
