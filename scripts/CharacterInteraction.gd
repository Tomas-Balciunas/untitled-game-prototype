extends Resource

class_name CharacterInteraction

const MENU_TALK = "menu_talk"
const BATTLE_EVENT = "battle_event"


func get_chatter(_topic: String) -> String:
	return ""

func get_dialogue(_topic: String, _id: String) -> Dictionary:
	return {}

func get_topic(_topic: String) -> Dictionary:
	return {}
	
func get_available_topics() -> Dictionary:
	return {}

func get_damaged_line(_key: String, _amt: int, _ctx: DamageContext = null) -> String:
	return ""

func get_attacking_line(_key: String, _source: CharacterInstance, _targets: Array) -> String:
	return ""
