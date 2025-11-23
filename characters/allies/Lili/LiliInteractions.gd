extends CharacterInteraction

class_name LiliInteractions


const FIRST_ENCOUNTER_SECOND = "first_encounter_continued"

var menu := [
	{
		"type": "text",
		"text": ["test 1", "test 2"]
	},
	{
		"type": "text",
		"text": ["test 3", "test 4"]
	},
]

#var conversations := {
	#FIRST_ENCOUNTER: ["Greetings dungeon delver", "My name is Lili", "Pleasure to meet you"]
#}

var conversations := [
	{
		ID: FIRST_ENCOUNTER,
		"priority": 500,
		"event": [
			{
				"type": "text",
				"text": ["Greetings dungeon delver", "My name is Lili", "Pleasure to meet you"]
			}
		],
		"conditions": [FIRST_ENCOUNTER],
		"on_completed": "first_encounter_continued"
	},
	{
		"id": FIRST_ENCOUNTER_SECOND,
		"priority": 500,
		"event": [{
			"type": "text",
			"text": ["My party's left me..", "Perhaps I could join you?"]
		}],
		"conditions": [
			{
				TYPE: SELF,
				STATE: AVAILABLE,
				CONTAINS: true,
				TAGS: [FIRST_ENCOUNTER_SECOND]
			},
			{
				TYPE: CHARACTER,
				ID: "character_id",
				STATE: COMPLETED,
				CONTAINS: false,
				TAGS: [FIRST_ENCOUNTER_SECOND]
			}
		]
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

var battle_events := {
	
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

func get_chatter(topic: String) -> String:
	if chatter.has(topic):
		return chatter.topic
	
	return ""
	
func get_conversation(_id: String = "") -> Array:
	return conversations
	
func get_event(_id: String) -> Array:
	if events.has(_id):
		return events[_id]
	
	return []
	
func get_battle_event(_id: String) -> Array:
	if battle_events.has(_id):
		return battle_events[_id]
	
	return []

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
