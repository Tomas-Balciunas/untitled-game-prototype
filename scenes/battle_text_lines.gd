extends Panel

@onready var cont = $MarginContainer/TextContainer

func _ready():
	BattleTextLines.register_label(cont)
