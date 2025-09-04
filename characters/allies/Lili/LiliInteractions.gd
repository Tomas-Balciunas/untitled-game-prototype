extends CharacterInteraction

class_name LiliInteractions

func _init():
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
		}
	}
