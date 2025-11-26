extends CharacterInteraction

class_name LiliInteractions


const FIRST_ENCOUNTER_SECOND = "first_encounter_continued"
const RECRUIT_PARTY_FULL = "recruit_party_full"
const RECRUIT_LILI_AGAIN = "recruit_lili_again"

const ALLOWED_TO_JOIN = "allowed_to_join"
const DISALLOWED_TO_JOIN = "disallowed_to_join"

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
		PRIORITY: 10,
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
			MARK_COMPLETED: [ {ID: FIRST_ENCOUNTER }],
			MARK_AVAILABLE: [{ ID: FIRST_ENCOUNTER_SECOND }]
		}
	},
	{
		ID: FIRST_ENCOUNTER_SECOND,
		PRIORITY: 10,
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
				TEXT: ["My party's been..", "Perhaps I could join you?"]
			},
			{
				TYPE: CHOICE,
				CHOICES: [
					{
						ID: ALLOWED_TO_JOIN, 
						BTN_TEXT: "accept"
					}, 
					{
						ID: DISALLOWED_TO_JOIN, 
						BTN_TEXT: "refuse"
					}
				],
				TEXT: "Allow Lili to join the party?"
			},
			{
				CONDITIONS: [DISALLOWED_TO_JOIN],
				TYPE: TEXT,
				TEXT: ["Okay..."]
			},
		],
		ON_COMPLETED: {
			MARK_COMPLETED: [{ 
				ID: FIRST_ENCOUNTER_SECOND, 
				CONDITIONS: {
					CHOICES: [ALLOWED_TO_JOIN]
				} 
			}]
		},
		CALLBACK: {
			FUNC: LiliController.RECRUIT_LILI,
			CONDITIONS: {
				CHOICES: [ALLOWED_TO_JOIN]
			}
		}
	},
	{
		ID: RECRUIT_PARTY_FULL,
		PRIORITY: 50,
		RECURRING: true,
		EVENT: [{
			TYPE: TEXT,
			TEXT: ["It seems like there's no place for me.."]
		}],
		ON_COMPLETED: {
			MARK_COMPLETED: [{ ID: RECRUIT_PARTY_FULL }],
			MARK_AVAILABLE: [{ ID: RECRUIT_LILI_AGAIN }]
		},
		CONDITIONS: [{
			TYPE: SELF, 
			STATE: AVAILABLE,
			CONTAINS: true,
			TAGS: [RECRUIT_PARTY_FULL]
		}]
	},
	{
		ID: RECRUIT_LILI_AGAIN,
		PRIORITY: 50,
		RECURRING: true,
		CONDITIONS: [
			{
				TYPE: SELF,
				STATE: AVAILABLE,
				CONTAINS: true,
				TAGS: [RECRUIT_LILI_AGAIN]
			},
		],
		EVENT: [
			{
				TYPE: TEXT,
				TEXT: ["Hey", "Have you found space for me?"]
			},
			{
				TYPE: CHOICE,
				CHOICES: [
					{
						ID: ALLOWED_TO_JOIN, 
						BTN_TEXT: "yes"
					}, 
					{
						ID: DISALLOWED_TO_JOIN, 
						BTN_TEXT: "no"
					}
				],
				TEXT: "Allow Lili to join the party?"
			},
			{
				CONDITIONS: [DISALLOWED_TO_JOIN],
				TYPE: TEXT,
				TEXT: ["Just kill someone"]
			},
		],
		ON_COMPLETED: {
			MARK_COMPLETED: [{
				ID: RECRUIT_LILI_AGAIN,
				CONDITIONS: {
					CHOICES: [ALLOWED_TO_JOIN]
				}
			}]
		},
		CALLBACK: {
			FUNC: LiliController.RECRUIT_LILI,
			CONDITIONS: {
				CHOICES: [ALLOWED_TO_JOIN]
			}
		}
	},
	
	# ----- DEFAULT -----
	{
		PRIORITY: 1,
		PERSISTENT: true,
		RANDOM: true,
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
