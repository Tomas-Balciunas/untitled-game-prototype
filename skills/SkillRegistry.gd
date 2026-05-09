extends Node

var skills := {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths: Array[String] = [
		# existing
		"res://skills/_offensive/poison_strike.tres",
		"res://skills/_offensive/stun_skill.tres",
		"res://skills/_defensive/_heal/single heal.tres",
		"res://skills/_defensive/_heal/row heal.tres",
		# fighter
		"res://skills/_offensive/power_strike.tres",
		"res://skills/_offensive/cleave.tres",
		# knight
		"res://skills/_offensive/shield_bash.tres",
		"res://skills/_offensive/holy_strike.tres",
		# mage
		"res://skills/_offensive/arcane_bolt.tres",
		"res://skills/_offensive/arcane_blast.tres",
		# priest
		"res://skills/_offensive/smite.tres",
		# thief
		"res://skills/_offensive/shadow_strike.tres",
	]

	for path in res_paths:
		var res := ResourceLoader.load(path)
		if res:
			register_skill(res)

func register_skill(skill: Skill) -> void:
	if skill.id in skills:
		push_warning("Duplicate skill id: %s" % skill.id)

	skills[skill.id] = skill

func get_skill(id: String) -> Skill:
	if skills.has(id):
		return skills[id]

	push_error("Skill not found by %s" % id)
	return null
