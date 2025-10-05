extends Interactable

func _interact():
	if GameState.is_busy():
		return
		
	RestBus.enter_rest_area_requested.emit()
		
