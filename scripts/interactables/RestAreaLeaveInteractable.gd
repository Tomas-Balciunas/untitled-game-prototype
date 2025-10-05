extends Interactable

func _interact():
	RestBus.exit_rest_area_requested.emit()
