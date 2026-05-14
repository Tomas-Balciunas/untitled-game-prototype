extends Resource

class_name CharacterChatter


@export var lines: Dictionary = {}


func get_chatter(topic: String) -> String:
	var bucket: Dictionary = lines.get(topic, {})
	var default: Array = bucket.get("default", [])

	if default.is_empty():
		return ""

	return default.pick_random()


func get_damaged_line(key: String, _amount: int, _ctx: ActionContext = null) -> String:
	return get_chatter(key)


func get_attacking_line(key: String, _source: Character, _targets: Array) -> String:
	return get_chatter(key)
