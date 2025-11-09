extends CharacterInteraction

class_name SkeltalInteractions

const FATAL_HIT = "fatal_hit"

func _init() -> void:
	interactions = {
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
		},
		"damaged": {
			
		}
	}
	
	chatter = {
		"damaged": "Owch!"
	}
