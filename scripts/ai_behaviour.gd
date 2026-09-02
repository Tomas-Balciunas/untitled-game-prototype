extends Resource

class_name AiBehaviour


func _init() -> void:
	pass

func choose_action(actor: Character, enemies: Array[Character], allies: Array[Character]) -> Array:
	var valid_targets := enemies.filter(func(p: Character) -> bool: return p.is_dead == false)
	if valid_targets.is_empty():
		return []

	var target: Character = valid_targets.pick_random()
	
	return [target, BasicAttack.new()]
