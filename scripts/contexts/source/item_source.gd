extends ContextSource
class_name ItemSource


func _init(c: CharacterInstance, i: ItemInstance) -> void:
	character = c
	item = i
	
func get_type() -> SourceType:
	return ContextSource.SourceType.ITEM

func get_source_name() -> String:
	return item.get_item_name()
