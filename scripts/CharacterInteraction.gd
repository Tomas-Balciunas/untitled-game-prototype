extends Resource

class_name CharacterInteraction

const MENU_TALK = "menu_talk"
const BATTLE_EVENT = "battle_event"
const FIRST_ENCOUNTER = "first_encounter"

func get_chatter(_topic: String) -> String:
	return ""

func get_conversation(_id: String = "") -> Array:
	return []

func get_event(_id: String) -> Array:
	return []
	
func get_battle_event(_id: String) -> Array:
	return []

func get_damaged_line(_key: String, _amt: int, _ctx: DamageContext = null) -> String:
	return ""

func get_attacking_line(_key: String, _source: CharacterInstance, _targets: Array) -> String:
	return ""
