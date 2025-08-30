extends Panel

@onready var cont = $MarginContainer/TextContainer

func _ready():
	BattleTextLines.register_label(cont)

func enable_battle_text_lines_ui():
	self.visible = true

func disable_battle_text_lines_ui():
	self.visible = false
