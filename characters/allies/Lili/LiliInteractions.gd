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


var interactions := [
	{
		ID: FIRST_ENCOUNTER,
		PRIORITY: 500,
		EVENT: [
			{
				TYPE: TEXT,
				TEXT: ["Greetings dungeon delver", "My name is Lili", "Pleasure to meet you"]
			}
		],
		CONDITIONS: [
			{
				TYPE: SELF,
				STATE: AVAILABLE,
				CONTAINS: true,
				TAGS: [FIRST_ENCOUNTER]
			},
		],
		ON_COMPLETED: {
			MARK_COMPLETED: [FIRST_ENCOUNTER],
			MARK_AVAILABLE: [FIRST_ENCOUNTER_SECOND]
		}
	},
	{
		ID: FIRST_ENCOUNTER_SECOND,
		PRIORITY: 500,
		CONDITIONS: [
			{
				TYPE: SELF,
				STATE: AVAILABLE,
				CONTAINS: true,
				TAGS: [FIRST_ENCOUNTER_SECOND]
			},
		],
		EVENT: [
			{
				TYPE: TEXT,
				TEXT: ["My party's left me..", "Perhaps I could join you?"]
			},
			#{
				#TYPE: "choice",
				#"choices": [{"id": "allowed_to_join", "btn_text": "yes"}, {"id": "disallowed_to_join", "btn_text": "no"}],
				#"text": "Allow Lili to join the party?"
			#},
			#{
				#TYPE: TEXT,
				#TEXT: ["My party's left me..", "Perhaps I could join you?"]
			#},
			#{
				#TYPE: TEXT,
				#TEXT: ["My party's left me..", "Perhaps I could join you?"]
			#},
		],
		ON_COMPLETED: {
			MARK_COMPLETED: [FIRST_ENCOUNTER_SECOND]
		},
		"callback": {
			"func": "recruit_lili",
			CONDITIONS: {
				"choices": ["allowed_to_join"]
			}
		}
	},
	
	
	# ----- DEFAULT -----
	{
		PRIORITY: 1,
		PERSISTENT: true,
		EVENT: [
			{
				TYPE: TEXT,
				TEXT: ["Oh!"]
			},
			{
				TYPE: TEXT,
				TEXT: ["What's up?"]
			},
			{
				TYPE: TEXT,
				TEXT: ["Hey"]
			}
		],
	}
]

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


func _get_default_tags() -> Array:
	return [FIRST_ENCOUNTER]


func get_chatter(topic: String) -> String:
	if chatter.has(topic):
		return chatter.topic
	
	return ""


func get_interactions() -> Array:
	return interactions


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
