class_name RobotAppearance
extends Resource
## Opaque material colors. Profile alpha cannot make a competitor invisible.

@export var body_color: Color = Color("44ccee")
@export var accent_color: Color = Color.WHITE
var nickname: String = "Player"
var slots: Dictionary = {"head": "", "hat": "", "torso": "", "arms": "", "legs": ""}


static func from_profile(profile: PlayerProfileData) -> RobotAppearance:
	if profile == null or not PlayerProfileData.validate(profile.to_dictionary()):
		return null
	var appearance := RobotAppearance.new()
	appearance.body_color = Color.html(profile.body_color)
	appearance.accent_color = Color.html(profile.accent_color)
	appearance.body_color.a = 1.0
	appearance.accent_color.a = 1.0
	appearance.nickname = profile.nickname
	appearance.slots = profile.cosmetic_slots.duplicate(true)
	return appearance
