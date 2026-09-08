class_name PlaygroundStation
extends RefCounted
## Developer-only geometry catalog. Coordinates are world pixels; floor tops are explicit.

var id: String
var spawn: Vector2
var boxes: Array[Rect2] = []
var polygons: Array[PackedVector2Array] = []
var envelope := Rect2(-1000, -1000, 4200, 2500)


func _init(key: String, location: Vector2) -> void:
	id = key
	spawn = location


static func catalog() -> Array[PlaygroundStation]:
	var result: Array[PlaygroundStation] = []
	var station := PlaygroundStation.new("GROUND", Vector2(0, 450))
	station.boxes = [Rect2(-800, 500, 3600, 80)]
	result.append(station)
	station = PlaygroundStation.new("AIR", Vector2(0, 450))
	station.boxes = [Rect2(-300, 500, 600, 80), Rect2(750, 700, 900, 80)]
	result.append(station)
	station = PlaygroundStation.new("VARIABLE", Vector2(0, 450))
	station.boxes = [Rect2(-700, 500, 2000, 80)]
	result.append(station)
	station = PlaygroundStation.new("COYOTE", Vector2(0, 450))
	station.boxes = [Rect2(-600, 500, 900, 80), Rect2(700, 500, 1000, 80), Rect2(-600, 1100, 2300, 80)]
	result.append(station)
	station = PlaygroundStation.new("DOUBLE", Vector2(0, 450))
	station.boxes = [Rect2(-500, 500, 850, 80), Rect2(450, 230, 700, 40)]
	result.append(station)
	station = PlaygroundStation.new("WALL_SLIDE", Vector2(163, -400))
	station.boxes = [Rect2(180, -700, 60, 1300), Rect2(-700, 600, 1500, 80)]
	result.append(station)
	station = PlaygroundStation.new("WALL_JUMP", Vector2(163, -100))
	station.boxes = [Rect2(180, -700, 60, 1300), Rect2(-700, 600, 1500, 80), Rect2(-400, -150, 300, 40)]
	result.append(station)
	station = PlaygroundStation.new("DASH", Vector2(0, 450))
	station.boxes = [Rect2(-850, 500, 1700, 80), Rect2(-900, -650, 50, 1230), Rect2(850, -650, 50, 1230)]
	result.append(station)
	station = PlaygroundStation.new("TERMINAL", Vector2(0, -2450))
	station.boxes = [Rect2(-600, 500, 1200, 80)]
	station.envelope = Rect2(-1200, -3300, 2800, 4600)
	result.append(station)
	station = PlaygroundStation.new("SLOPE", Vector2(0, 450))
	station.boxes = [Rect2(-700, 500, 1000, 80), Rect2(1100, 100, 1000, 80)]
	station.polygons = [PackedVector2Array([Vector2(300, 500), Vector2(1100, 100), Vector2(1100, 580), Vector2(300, 580)])]
	result.append(station)
	station = PlaygroundStation.new("STEEP", Vector2(650, -260))
	station.boxes = [Rect2(-700, 500, 1000, 80)]
	station.polygons = [PackedVector2Array([Vector2(300, 500), Vector2(800, -500), Vector2(900, 580), Vector2(300, 580)])]
	result.append(station)
	station = PlaygroundStation.new("SPEED", Vector2(0, 450))
	station.boxes = [Rect2(-800, 500, 7000, 80), Rect2(5600, -100, 8, 600)]
	station.envelope = Rect2(-1200, -1000, 8400, 2500)
	result.append(station)
	for key: String in ["ONE_WAY", "MOVING", "BREAKABLE", "JUMP_PAD"]:
		station = PlaygroundStation.new(key, Vector2(0, 450))
		station.boxes = [Rect2(-700, 500, 950, 80), Rect2(800, 500, 1100, 80), Rect2(250, 900, 550, 80)]
		result.append(station)
	return result
