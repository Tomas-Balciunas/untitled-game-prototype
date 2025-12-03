extends InterfaceBase

@onready var battle_controls: Control = $BattleControls

func _set_visibility(mode: InterfaceRoot.Mode) -> void:
	visible = mode == InterfaceRoot.Mode.BATTLE
