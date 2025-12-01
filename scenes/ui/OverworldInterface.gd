extends InterfaceBase

func _set_visibility(mode: InterfaceRoot.Mode) -> void:
	visible = mode == InterfaceRoot.Mode.OVERWORLD
