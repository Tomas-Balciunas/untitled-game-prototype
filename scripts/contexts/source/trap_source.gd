extends ContextSource
class_name TrapSource


func _init(t: Trap) -> void:
	trap = t
	
func get_type() -> SourceType:
	return ContextSource.SourceType.TRAP

func get_source_name() -> String:
	return trap.name
