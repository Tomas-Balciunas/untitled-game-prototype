extends ItemResource
class_name QuestItemResource

func _init() -> void:
	type = ItemTypes.ItemType.QUEST
	
	if not id:
		id = GameState.generate_id()


func _build_instance() -> QuestItem:
	var quest_item: QuestItem = QuestItem.new()
	quest_item.id = id
	quest_item.item_name = name
	quest_item.type = type
	quest_item.item_description = description
	quest_item.value = 0
	
	return quest_item
