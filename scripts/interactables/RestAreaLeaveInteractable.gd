extends Interactable

func _interact() -> void:
	RestBus.exit_rest_area_requested.emit()
