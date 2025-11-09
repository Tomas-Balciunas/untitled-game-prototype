extends CharacterInteraction

class_name LiliInteractions

const FATAL_HIT = "fatal_hit"


var interactions := {
	MENU_TALK: {
		"random_01": {
			"type": "text",
			"text": ["test 1", "test 2"]
		},
		"random_02": {
			"type": "text",
			"text": ["test 3", "test 4"]
		},
	},
	BATTLE_EVENT: {
		FATAL_HIT: {
			"type": "text",
			"text": ["this wont hurt me!"]
		}
	}
}

var chatter := {
	"damaged": {
		"default": ["owch", "ugh"],
		"special": {}
	},
	"attacking": {
		"default": ["Hiyah!", "Die!"],
		"special": {}
	}
}

func get_damaged_line(key: String, _amt: int, _ctx: DamageContext = null) -> String:
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
