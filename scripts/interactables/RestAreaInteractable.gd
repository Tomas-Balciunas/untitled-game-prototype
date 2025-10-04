extends Interactable

func _interact():
	if GameState.is_busy():
		return
		
	RestManager.enter_rest_area()
		
