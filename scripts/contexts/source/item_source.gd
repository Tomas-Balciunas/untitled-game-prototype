extends ContextSource
class_name ItemSource


func _init(c: Character, i: Item) -> void:
	character = c
	item = i
	
func get_type() -> SourceType:
	return ContextSource.SourceType.ITEM

func get_source_name() -> String:
	return item.get_item_name()


func game_save() -> Dictionary:
	var data := super.game_save()
	data["character_id"] = character.resource.id if character and character.resource else ""
	data["item"] = item.game_save() if item else {}
	return data


# Items aren't always retrievable post-consume; rebuild a detached Item instance
# for display/source attribution purposes only.
static func from_save(data: Dictionary) -> ItemSource:
	var char_inst := ContextSource._find_character_by_id(data.get("character_id", ""))
	if char_inst == null:
		return null
	var item_data: Dictionary = data.get("item", {})
	var item_inst := Item.create_from_save(item_data) if not item_data.is_empty() else null
	return ItemSource.new(char_inst, item_inst)
