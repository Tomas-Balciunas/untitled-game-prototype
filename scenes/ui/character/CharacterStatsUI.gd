extends Node

@onready var exp_value: Label = $Stats/Exp/ExpValue
@onready var hp_value: Label        = $Stats/HP/HpValue
@onready var mp_value: Label        = $Stats/MP/MpValue
@onready var sp_value: Label        = $Stats/SP/SpValue
@onready var attack_value: Label    = $Stats/Attack/AttackValue
@onready var speed_value: Label     = $Stats/Speed/SpeedValue
@onready var defense_value: Label   = $Stats/Defense/DefenseValue
@onready var magic_power_value: Label   = $Stats/MagicPower/MagicPowerValue
@onready var divine_power_value: Label  = $Stats/DivinePower/DivinePowerValue
@onready var magic_defense_value: Label = $Stats/MagicDefense/MagicDefenseValue
@onready var resistance_value: Label    = $Stats/Resistance/ResistanceValue

func bind_character(character: CharacterInstance) -> void:
	var s := character.stats
	exp_value.text = "%s/%s" % [
		character.current_experience,
		character.resource.experience_manager.exp_needed_to_next_level(character)
	]

	hp_value.text            = str(s.get_final_stat(Stats.HEALTH))
	mp_value.text            = str(s.get_final_stat(Stats.MANA))
	attack_value.text        = str(s.get_final_stat(Stats.ATTACK))
	speed_value.text         = str(s.get_final_stat(Stats.SPEED))
	defense_value.text       = str(s.get_final_stat(Stats.DEFENSE))
	magic_power_value.text   = str(s.get_final_stat(Stats.MAGIC_POWER))
	divine_power_value.text  = str(s.get_final_stat(Stats.DIVINE_POWER))
	magic_defense_value.text = str(s.get_final_stat(Stats.MAGIC_DEFENSE))
	resistance_value.text    = str(s.get_final_stat(Stats.RESISTANCE))
