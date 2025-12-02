extends Control
class_name ChestInterface

enum Mode { LOCKED, OPEN, _HIDE }

@onready var chest_opener_choice: ChestOpenerChoiceInterface = %ChestOpenerChoice
@onready var chest_content: ChestContentInterface = %ChestContent


func _ready() -> void:
	chest_opener_choice.close_chest_opener_choice.connect(_on_close)
	chest_content.close_chest_content.connect(_on_close)

func _set_mode(mode: Mode) -> void:
	chest_opener_choice.visible = mode == Mode.LOCKED
	chest_content.visible = mode == Mode.OPEN


func display_chest_opener_choice() -> void:
	chest_opener_choice.init()
	_set_mode(Mode.LOCKED)


func display_chest_content(c: Chest) -> void:
	chest_content.init(c)
	_set_mode(Mode.OPEN)


func _on_close() -> void:
	_set_mode(Mode._HIDE)
	hide()
