extends Node

var events: Dictionary = {
	# eventually events will move into their separate files i think
	"test_event_000": [
		{
			"type": "text",
			"speaker": "Unknown Entity",
			"text": [
				"Abandon all hope",
				"Ye who enter here"
			]
		},
		{
			"type": "encounter",
			"arena": "arena_default_00", 
			"enemies": ["e_enemy_002", "0000"]
		},
		{
			"type": "text",
			"speaker": "Unknown Entity",
			"text": [
				"Well done",
				"You may pass"
			]
		}
	]
}

func get_event(id: String):
	if events.has(id):
		return events[id]
	print("Event not found")
	return null
