extends ContextSource
class_name EffectSource


func _init(e: Effect, c: Character = null) -> void:
	effect = e
	character = c
	
func get_type() -> SourceType:
	return ContextSource.SourceType.EFFECT

func get_source_name() -> String:
	return effect._get_name()
