extends Job

class_name PriestClass

const ROW_HEAL = preload("res://skills/_defensive/_heal/row heal.tres")


func get_skills_for_level(lvl: int) -> Array:
	match lvl:
		3: return [ROW_HEAL]
	return []
