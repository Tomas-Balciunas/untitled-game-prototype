extends Node3D

class_name HealthBar

@onready var progress_bar: ProgressBar = $HealthbarViewport/ProgressBar

func _ready() -> void:
	if GameState.current_state == GameState.States.IN_BATTLE:
		visible = true

func set_value(val: int) -> void:
	progress_bar.value = val

func set_max_value(val: int) -> void:
	progress_bar.max_value = val
