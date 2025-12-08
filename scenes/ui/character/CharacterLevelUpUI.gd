extends Node

@onready var str_attr: Label = $Attributes/Values/STR/Value
@onready var iq_attr: Label  = $Attributes/Values/IQ/Value
@onready var pie_attr: Label = $Attributes/Values/PIE/Value
@onready var vit_attr: Label = $Attributes/Values/VIT/Value
@onready var dex_attr: Label = $Attributes/Values/DEX/Value
@onready var spd_attr: Label = $Attributes/Values/SPD/Value
@onready var luk_attr: Label = $Attributes/Values/LUK/Value

@onready var str_dec: Button = $Attributes/Values/STR/Dec
@onready var str_inc: Button = $Attributes/Values/STR/Inc

@onready var iq_dec: Button  = $Attributes/Values/IQ/Dec
@onready var iq_inc: Button  = $Attributes/Values/IQ/Inc

@onready var pie_dec: Button = $Attributes/Values/PIE/Dec
@onready var pie_inc: Button = $Attributes/Values/PIE/Inc

@onready var vit_dec: Button = $Attributes/Values/VIT/Dec
@onready var vit_inc: Button = $Attributes/Values/VIT/Inc

@onready var dex_dec: Button = $Attributes/Values/DEX/Dec
@onready var dex_inc: Button = $Attributes/Values/DEX/Inc

@onready var spd_dec: Button = $Attributes/Values/SPD/Dec
@onready var spd_inc: Button = $Attributes/Values/SPD/Inc

@onready var luk_dec: Button = $Attributes/Values/LUK/Dec
@onready var luk_inc: Button = $Attributes/Values/LUK/Inc

@onready var points_display: Label = $Points

var character: CharacterInstance
#TODO: fix this garbage holy shit
func bind_character(chara: CharacterInstance) -> void:
	character = chara
	_setup_attribute_buttons()
	_update_attribute_labels()
	update_points()
	
func _safe_connect(button: Button, signal_name: String, callable: Callable) -> void:
	if not button.is_connected(signal_name, callable):
		button.connect(signal_name, callable)
	
func _setup_attribute_buttons() -> void:
	_safe_connect(str_dec, "pressed", Callable(self, "_on_attribute_changed").bind("STR", -1))
	_safe_connect(str_inc, "pressed", Callable(self, "_on_attribute_changed").bind("STR", 1))

	_safe_connect(iq_dec, "pressed", Callable(self, "_on_attribute_changed").bind("IQ", -1))
	_safe_connect(iq_inc, "pressed", Callable(self, "_on_attribute_changed").bind("IQ", 1))

	_safe_connect(pie_dec, "pressed", Callable(self, "_on_attribute_changed").bind("PIE", -1))
	_safe_connect(pie_inc, "pressed", Callable(self, "_on_attribute_changed").bind("PIE", 1))

	_safe_connect(vit_dec, "pressed", Callable(self, "_on_attribute_changed").bind("VIT", -1))
	_safe_connect(vit_inc, "pressed", Callable(self, "_on_attribute_changed").bind("VIT", 1))

	_safe_connect(dex_dec, "pressed", Callable(self, "_on_attribute_changed").bind("DEX", -1))
	_safe_connect(dex_inc, "pressed", Callable(self, "_on_attribute_changed").bind("DEX", 1))

	_safe_connect(spd_dec, "pressed", Callable(self, "_on_attribute_changed").bind("SPD", -1))
	_safe_connect(spd_inc, "pressed", Callable(self, "_on_attribute_changed").bind("SPD", 1))

	_safe_connect(luk_dec, "pressed", Callable(self, "_on_attribute_changed").bind("LUK", -1))
	_safe_connect(luk_inc, "pressed", Callable(self, "_on_attribute_changed").bind("LUK", 1))

	_update_attribute_labels()
	
func _on_attribute_changed(attr_name: String, delta: int) -> void:
	match attr_name:
		"STR":
			character.level_up_attributes.strength = whatever(delta, character.level_up_attributes.strength)
		"IQ":
			character.level_up_attributes.intelligence = whatever(delta, character.level_up_attributes.intelligence)
		"PIE":
			character.level_up_attributes.piety = whatever(delta, character.level_up_attributes.piety)
		"VIT":
			character.level_up_attributes.vitality = whatever(delta, character.level_up_attributes.vitality)
		"DEX":
			character.level_up_attributes.dexterity = whatever(delta, character.level_up_attributes.dexterity)
		"SPD":
			character.level_up_attributes.speed = whatever(delta, character.level_up_attributes.speed)
		"LUK":
			character.level_up_attributes.luck = whatever(delta, character.level_up_attributes.luck)

	character.level_up_attributes.strength = max(character.level_up_attributes.strength, 0)
	character.level_up_attributes.intelligence = max(character.level_up_attributes.intelligence, 0)
	character.level_up_attributes.piety = max(character.level_up_attributes.piety, 0)
	character.level_up_attributes.vitality = max(character.level_up_attributes.vitality, 0)
	character.level_up_attributes.dexterity = max(character.level_up_attributes.dexterity, 0)
	character.level_up_attributes.speed = max(character.level_up_attributes.speed, 0)
	character.level_up_attributes.luck = max(character.level_up_attributes.luck, 0)
	
	character.fill_attributes()
	_update_attribute_labels()
	update_points()
	StatCalculator.recalculate_all_stats(character)
	
func whatever(delta: int, attr: int) -> int:
	var points := character.unspent_attribute_points
	if delta > 0 and points <= 0:
		return attr
	if delta < 0 and attr <= 0:
		return attr

	attr += delta
	character.unspent_attribute_points = clamp(points - delta, 0, points)
	return attr
	
func _update_attribute_labels() -> void:
	str_attr.text = str(character.attributes.strength)
	iq_attr.text  = str(character.attributes.intelligence)
	pie_attr.text = str(character.attributes.piety)
	vit_attr.text = str(character.attributes.vitality)
	dex_attr.text = str(character.attributes.dexterity)
	spd_attr.text = str(character.attributes.speed)
	luk_attr.text = str(character.attributes.luck)

func update_points() -> void:
	points_display.text = "Points left: %s" % character.unspent_attribute_points
