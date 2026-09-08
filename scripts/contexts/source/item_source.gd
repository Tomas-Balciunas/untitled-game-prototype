extends ContextSource
class_name ItemSource

var item_name: String = ""


func _init(c: Character, i: Item) -> void:
	character = c
	item = i
	item_name = i.get_item_name() if i else ""

func get_type() -> SourceType:
	return ContextSource.SourceType.ITEM

func get_source_name() -> String:
	return item.get_item_name() if item else item_name


func game_save() -> Dictionary:
	var data := super.game_save()
	data["character_id"] = character.resource.id if character and character.resource else ""
	data["item_id"] = item.id if item else ""
	data["item_name"] = get_source_name()
	return data


static func from_save(data: Dictionary) -> ItemSource:
	var char_inst := ContextSource._find_character_by_id(data.get("character_id", ""))
	if char_inst == null:
		return null
	var src := ItemSource.new(char_inst, null)
	src.item_name = data.get("item_name", "")
	return src
