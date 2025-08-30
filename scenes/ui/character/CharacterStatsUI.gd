extends Node

@onready var hp_value        = $Stats/HP/HpValue
@onready var mp_value        = $Stats/MP/MpValue
@onready var sp_value        = $Stats/SP/SpValue
@onready var attack_value    = $Stats/Attack/AttackValue
@onready var speed_value     = $Stats/Speed/SpeedValue
@onready var defense_value   = $Stats/Defense/DefenseValue
@onready var magic_power_value   = $Stats/MagicPower/MagicPowerValue
@onready var divine_power_value  = $Stats/DivinePower/DivinePowerValue
@onready var magic_defense_value = $Stats/MagicDefense/MagicDefenseValue
@onready var resistance_value    = $Stats/Resistance/ResistanceValue

func bind_character(character: CharacterInstance):
	hp_value.text            = str(character.stats.max_health)
	mp_value.text            = str(character.stats.max_mana)
	sp_value.text            = str(character.stats.max_sp)
	attack_value.text        = str(character.stats.attack)
	speed_value.text         = str(character.stats.speed)
	defense_value.text       = str(character.stats.defense)
	magic_power_value.text   = str(character.stats.magic_power)
	divine_power_value.text  = str(character.stats.divine_power)
	magic_defense_value.text = str(character.stats.magic_defense)
	resistance_value.text    = str(character.stats.resistance)
