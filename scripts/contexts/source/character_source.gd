extends ContextSource
class_name CharacterSource


func _init(c: Character) -> void:
	character = c
	
func get_type() -> SourceType:
	return ContextSource.SourceType.CHARACTER

func get_source_name() -> String:
	return character.resource.name
