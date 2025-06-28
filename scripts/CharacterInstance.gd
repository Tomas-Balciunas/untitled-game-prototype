extends RefCounted

class_name CharacterInstance

signal health_changed(new_health)

var resource: CharacterResource
var current_health: int
var max_health: int
var current_mana: int
var max_mana: int
var current_experience: int
var status_effects: Array = []

func _init(res: CharacterResource) -> void:
	resource = res

	current_health = res.health_points
	max_health = res.health_points
	current_mana = res.mana_points
	max_mana = res.mana_points
	current_experience = res.experience

func set_current_health(new_health: int):
	current_health = new_health
	emit_signal("health_changed", new_health)
