extends Triggerable
class_name MapTransitionTrigger

@export var map_data: MapData

func _fire(_data: Dictionary) -> void:
	if not map_data:
		push_error("No transition data found!")
		return
	TransitionManager.transit_to_map_start(map_data.id)
