class_name CharacterPresentationConfig
extends Resource
## Cosmetic tuning only. Never consulted by movement or ability rules.

@export_range(0.0, 1.0) var opponent_opacity: float = 0.3
@export_range(0.0, 3.0) var local_outline_width: float = 1.2
@export_range(0.0, 3.0) var opponent_outline_width: float = 0.0
@export var outline_color: Color = Color("d8eaf0")
@export_range(0.0, 1.0) var effect_intensity: float = 1.0


func valid() -> bool:
	return is_finite(opponent_opacity) and opponent_opacity >= 0 and opponent_opacity <= 1 and (
		is_finite(local_outline_width) and local_outline_width >= 0 and local_outline_width <= 3 and
		is_finite(opponent_outline_width) and opponent_outline_width >= 0 and opponent_outline_width <= 3 and
		is_finite(effect_intensity) and effect_intensity >= 0 and effect_intensity <= 1 and
		Vector4(outline_color.r, outline_color.g, outline_color.b, outline_color.a).is_finite())
