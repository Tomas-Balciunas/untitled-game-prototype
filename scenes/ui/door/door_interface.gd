extends Control
class_name DoorInterface

enum Mode { LOCKED, _HIDE }

@onready var door_opener_choice: DoorOpenerChoiceInterface = %DoorOpenerChoice


func _ready() -> void:
	door_opener_choice.close_door_opener_choice.connect(_on_close)

func _set_mode(mode: Mode) -> void:
	door_opener_choice.visible = mode == Mode.LOCKED


func display_door_opener_choice() -> void:
	door_opener_choice.init()
	_set_mode(Mode.LOCKED)


func _on_close() -> void:
	_set_mode(Mode._HIDE)
	hide()
