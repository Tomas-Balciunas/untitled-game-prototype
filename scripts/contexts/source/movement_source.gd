extends ContextSource
class_name MovementSource

	
func get_type() -> SourceType:
	return ContextSource.SourceType.MOVEMENT

func get_source_name() -> String:
	return 'Movement'
