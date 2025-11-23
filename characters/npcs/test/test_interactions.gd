extends CharacterInteraction

class_name TestNPCInteractions

var conversations := [
	{
		"priority": 500,
		"event": [
			{
				"type": "text",
				"text": ["Oh!", "Hello!"]
			}
		],
		"conditions": [FIRST_ENCOUNTER],
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

var events := {
	
}
	
func get_conversation(_id: String = "") -> Array:
	return conversations
	
func get_event(_id: String) -> Array:
	if events.has(_id):
		return events[_id]
	
	return []
