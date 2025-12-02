extends InterfaceBase

enum Mode { CHEST, CHARACTER_MENU }

@onready var character_menu: CharacterMenu = %CharacterMenu
@onready var chest: ChestInterface = %Chest


func _ready() -> void:
	ChestBus.display_chest_opener.connect(_on_chest_display_opener)
	ChestBus.display_chest_content.connect(_on_chest_display_content)
	CharacterBus.display_character_menu.connect(_on_character_menu_display)


func _set_mode(mode: Mode) -> void:
	character_menu.visible = mode == Mode.CHARACTER_MENU
	chest.visible = mode == Mode.CHEST


func _set_visibility(mode: InterfaceRoot.Mode) -> void:
	visible = mode == InterfaceRoot.Mode.OVERWORLD


func _on_chest_display_opener() -> void:
	chest.display_chest_opener_choice()
	_set_mode(Mode.CHEST)


func _on_chest_display_content(c: Chest) -> void:
	chest.display_chest_content(c)
	_set_mode(Mode.CHEST)


func _on_character_menu_display(c: CharacterInstance) -> void:
	character_menu.bind(c)
	_set_mode(Mode.CHARACTER_MENU)
