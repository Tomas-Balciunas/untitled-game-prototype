extends Panel

@onready var cont: RichTextLabel = $MarginContainer/TextContainer

func _ready() -> void:
	BattleTextLines.register_label(cont)

func enable_battle_text_lines_ui() -> void:
	self.visible = true

func disable_battle_text_lines_ui() -> void:
	self.visible = false
