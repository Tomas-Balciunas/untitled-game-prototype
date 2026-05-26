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
@onready var accuracy_value: Label = $Stats/Accuracy/AccuracyValue
@onready var evasion_value: Label = $Stats/Evasion/EvasionValue
@onready var healing_done_value: Label     = $Stats/HealingDone/HealingDoneValue
@onready var healing_received_value: Label = $Stats/HealingReceived/HealingReceivedValue

func bind_character(character: Character) -> void:
	var s := character.stats
	exp_value.text = "%s/%s" % [
		character.current_experience,
		character.experience_manager.exp_for_level(character.level + 1)
	]

	hp_value.text            = str(s.get_stat(Stats.StatRef.HEALTH))
	mp_value.text            = str(s.get_stat(Stats.StatRef.MANA))
	attack_value.text        = str(s.get_stat(Stats.StatRef.ATTACK))
	speed_value.text         = str(s.get_stat(Stats.StatRef.SPEED))
	defense_value.text       = str(s.get_stat(Stats.StatRef.DEFENSE))
	magic_power_value.text   = str(s.get_stat(Stats.StatRef.MAGIC_POWER))
	divine_power_value.text  = str(s.get_stat(Stats.StatRef.DIVINE_POWER))
	magic_defense_value.text = str(s.get_stat(Stats.StatRef.MAGIC_DEFENSE))
	resistance_value.text    = str(s.get_stat(Stats.StatRef.RESISTANCE))
	accuracy_value.text = str(s.get_stat(Stats.StatRef.ACCURACY))
	evasion_value.text = str(s.get_stat(Stats.StatRef.EVASION))
	healing_done_value.text     = "%d%%" % s.get_stat(Stats.StatRef.HEALING_DONE)
	healing_received_value.text = "%d%%" % s.get_stat(Stats.StatRef.HEALING_RECEIVED)
