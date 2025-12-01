extends Panel

@onready var name_label := $CharacterName
@onready var level_label := $LevelLabel
@onready var points_label := $PointsLabel
@onready var attr_labels := {
	"STR": $AttributesContainer/STR_Row/STR_Label,
	"IQ": $AttributesContainer/IQ_Row/IQ_Label,
	"PIE": $AttributesContainer/PIE_Row/PIE_Label,
	"VIT": $AttributesContainer/VIT_Row/VIT_Label,
	"DEX": $AttributesContainer/DEX_Row/DEX_Label,
	"SPD": $AttributesContainer/SPD_Row/SPD_Label,
	"LUK": $AttributesContainer/LUK_Row/LUK_Label
}
@onready var attr_buttons := {
	"STR": $AttributesContainer/STR_Row/STR_Button,
	"IQ": $AttributesContainer/IQ_Row/IQ_Button,
	"PIE": $AttributesContainer/PIE_Row/PIE_Button,
	"VIT": $AttributesContainer/VIT_Row/VIT_Button,
	"DEX": $AttributesContainer/DEX_Row/DEX_Button,
	"SPD": $AttributesContainer/SPD_Row/SPD_Button,
	"LUK": $AttributesContainer/LUK_Row/LUK_Button
}
@onready var done_button := $DoneButton

var character: CharacterInstance

func show_for_character(c: CharacterInstance) -> void:
	character = c
	character.gain_experience()
	update_ui()
	visible = true

func _ready() -> void:
	hide()
	for attr: String in attr_buttons.keys():
		attr_buttons[attr].pressed.connect(func() -> void:
			if character.increase_attribute(attr):
				update_ui()
		)
	done_button.pressed.connect(hide)

func update_ui() -> void:
	name_label.text = character.resource.name
	level_label.text = "Level: %d" % character.level
	points_label.text = "Points: %d" % character.unspent_attribute_points
	
	attr_labels["STR"].text = "STR: %d" % character.attributes.str
	attr_labels["IQ"].text = "IQ: %d" % character.attributes.iq
	attr_labels["PIE"].text = "PIE: %d" % character.attributes.pie
	attr_labels["VIT"].text = "VIT: %d" % character.attributes.vit
	attr_labels["DEX"].text = "DEX: %d" % character.attributes.dex
	attr_labels["SPD"].text = "SPD: %d" % character.attributes.spd
	attr_labels["LUK"].text = "LUK: %d" % character.attributes.luk
	
	for button: Button in attr_buttons.values():
		button.disabled = character.unspent_attribute_points == 0
