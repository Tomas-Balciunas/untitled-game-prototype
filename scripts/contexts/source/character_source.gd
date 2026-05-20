extends ContextSource
class_name CharacterSource


func _init(c: Character) -> void:
	character = c
	
func get_type() -> SourceType:
	return ContextSource.SourceType.CHARACTER

func get_source_name() -> String:
	return character.resource.name


func game_save() -> Dictionary:
	var data := super.game_save()
	data["character_id"] = character.resource.id if character and character.resource else ""
	return data


static func from_save(data: Dictionary) -> CharacterSource:
	var char_inst := ContextSource._find_character_by_id(data.get("character_id", ""))
	if char_inst == null:
		return null
	return CharacterSource.new(char_inst)
