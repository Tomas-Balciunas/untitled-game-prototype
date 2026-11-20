extends ContextSource
class_name MovementSource

var label: String

func _init(source_label: String = "Movement") -> void:
	label = source_label

func get_type() -> SourceType:
	return ContextSource.SourceType.MOVEMENT

func get_source_name() -> String:
	return label
