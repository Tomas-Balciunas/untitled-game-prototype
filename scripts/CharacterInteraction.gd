extends Resource

class_name CharacterInteraction

const MENU_TALK = "menu_talk"
const BATTLE_EVENT = "battle_event"

var interactions: Dictionary = {}

func get_dialogue(_topic: String, _id: String) -> Dictionary:
	var topic: Dictionary = interactions.get(_topic, {})
	return topic.get(_id, {})

func get_topic(_topic: String) -> Dictionary:
	return interactions.get(_topic, {})
	
func get_available_topics() -> Dictionary:
	return {}
