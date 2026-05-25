extends Job

class_name ThiefClass

const SHADOW_STRIKE = preload("res://skills/_offensive/shadow_strike.tres")
const SHADOW_VEIL = preload("res://effect/_passive/shadow_veil/shadow_veil.tres")


func get_skills_for_level(lvl: int) -> Array:
	match lvl:
		3: return [SHADOW_STRIKE]
	return []


func get_effects_for_level(lvl: int) -> Array:
	match lvl:
		5: return [SHADOW_VEIL]
	return []

func get_unequippable_gear() -> Array[ItemTypes.GearType]:
	return []
