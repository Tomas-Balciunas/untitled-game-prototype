extends RefCounted
class_name CharacterInstance

var resource: CharacterResource
var current_health: int
var current_mana: int
var current_experience: int
var status_effects: Array = []

func _init(res: CharacterResource) -> void:
	resource = res

	current_health = res.health_points
	current_mana = res.mana_points
	current_experience = res.experience
