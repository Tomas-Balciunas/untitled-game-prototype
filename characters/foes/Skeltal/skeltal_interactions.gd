extends CharacterInteraction

class_name SkeltalInteractions


var interactions := []

var chatter := {
	"damaged": {
		"default": ["*rattle*", "*krr*"],
		"special": {}
	},
	"attacking": {
		"default": ["*angry rattle*", "..."],
	}
}

func get_interactions() -> Array:
	return []

func get_chatter(_topic: String) -> String:
	return ""


func get_damaged_line(key: String, _amt: int, _ctx: ActionContext = null) -> String:
	var lines: Dictionary = chatter.get(key, {})
	var default: Array = lines.get("default", [])
	
	if !lines.is_empty():
		return default.pick_random()
	
	return ""
	
func get_attacking_line(key: String, _source: CharacterInstance, _targets: Array) -> String:
	var lines: Dictionary = chatter.get(key, {})
	var default: Array = lines.get("default", [])
	
	if !lines.is_empty():
		return default.pick_random()
		
	return ""
