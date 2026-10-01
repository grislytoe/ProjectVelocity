class_name IndustrialFoundryBackground
extends Node2D
## Presentation-only far layer. It has no collision, input or simulation processing.

const PLATE: Texture2D = preload("res://visuals/environment/industrial_foundry_far.webp")
const TILE_SIZE := Vector2(2048, 1024)
const FIRST_TILE := -1
const TILE_COUNT := 23


func _ready() -> void:
	name = "IndustrialFoundryFarArt"
	z_index = -100
	process_mode = Node.PROCESS_MODE_DISABLED
	queue_redraw()


func _draw() -> void:
	# A quiet matte wash keeps generated detail subordinate to collision silhouettes.
	draw_rect(Rect2(-2048, -900, 47104, 1200), ArtPalette.BACKGROUND)
	for index: int in range(FIRST_TILE, FIRST_TILE + TILE_COUNT):
		var rect := Rect2(index * TILE_SIZE.x, -850, TILE_SIZE.x, TILE_SIZE.y)
		draw_texture_rect(PLATE, rect, false, Color(0.58, 0.64, 0.68, 0.42))
	# Broad depth bands are deliberately non-interactive and never resemble a route edge.
	draw_rect(Rect2(-2048, 190, 47104, 340), Color(0.025, 0.04, 0.05, 0.26))
