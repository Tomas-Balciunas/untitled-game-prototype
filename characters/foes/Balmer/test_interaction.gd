extends CharacterInteraction

class_name TestInteractions

const FATAL_HIT = "fatal_hit"

func _init():
	interactions = {
		BATTLE_EVENT: {
			FATAL_HIT: {
				"type": "text",
				"text": ["this wont hurt me!"]
			}
		}
	}
