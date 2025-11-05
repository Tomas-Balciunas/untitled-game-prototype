extends Node

var skills := {}

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var res_paths: Array[String] = [
		"res://skills/_offensive/poison_strike.tres",
		"res://skills/_offensive/stun_skill.tres",
		"res://skills/_defensive/_heal/single heal.tres",
		"res://skills/_defensive/_heal/row heal.tres"
		
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
