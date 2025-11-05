extends Interactable

func _interact() -> void:
	if GameState.is_busy():
		return
		
	RestBus.enter_rest_area_requested.emit()
		
