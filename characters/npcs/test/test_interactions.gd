extends CharacterInteraction

class_name TestNPCInteractions

var interactions := [
	{
		PRIORITY: 500,
		EVENT: [
			{
				"type": "text",
				"text": ["Oh!", "Hello!"]
			}
		],
		CONDITIONS: [{
			
		}],
	},
	{
		"priority": 10,
		"event": [{
			"type": "text",
			"text": ["Hey"]
		}],
	},
	{
		"priority": 10,
		"event": [{
			"type": "text",
			"text": ["What's up?"]
		}],
	},
	{
		"priority": 10,
		"event": [{
			"type": "text",
			"text": ["Oh!"]
		}],
	}
]


func get_interactions() -> Array:
	return interactions
	
func get_chatter(_topic: String) -> String:
	return ""
