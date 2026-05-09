extends Job

class_name KnightClass

const HOLY_STRIKE = preload("res://skills/_offensive/holy_strike.tres")


func get_skills_for_level(lvl: int) -> Array:
	match lvl:
		3: return [HOLY_STRIKE]
	return []
