extends Job

class_name FighterClass

const CLEAVE = preload("res://skills/_offensive/cleave.tres")
const COUNTER_STRIKE = preload("res://effect/_passive/counter_strike/counter_strike.tres")


func get_skills_for_level(lvl: int) -> Array:
	match lvl:
		3: return [CLEAVE]
	return []


func get_effects_for_level(lvl: int) -> Array:
	match lvl:
		5: return [COUNTER_STRIKE]
	return []

func get_unequippable_gear() -> Array[ItemTypes.GearType]:
	return []
