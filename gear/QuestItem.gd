extends Item
class_name QuestItem


func game_save() -> Dictionary:
	return {
		"class": "QuestItem",
		"id": id,
		"name": item_name,
		"description": item_description,
		"type": type,
		"value": value,
	}


func game_load(data: Dictionary) -> void:
	id = data.get("id", "")
	item_name = data.get("name", "")
	item_description = data.get("description", "")
	type = data.get("type", ItemTypes.ItemType.QUEST) as ItemTypes.ItemType
	value = data.get("value", 0)
