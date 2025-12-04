extends InterfaceBase

func _set_visibility(mode: InterfaceRoot.Mode) -> void:
	visible = [InterfaceRoot.Mode.OVERWORLD, InterfaceRoot.Mode.BATTLE].has(mode)
