extends Node

var modifiers := {}
var basic_modifiers: Array[StatModifier] = []

func _ready() -> void:
	_register_all()

func _register_all() -> void:
	var basic_res_paths: Array[String] = [
		"res://stat/_modifier/basic_flat/AttackFlat.tres",
		"res://stat/_modifier/basic_flat/DefenseFlat.tres",
		"res://stat/_modifier/basic_flat/HealthFlat.tres",
		"res://stat/_modifier/basic_flat/ManaFlat.tres",
		"res://stat/_modifier/basic_flat/SpeedFlat.tres",
	]
	
	var res_paths: Array[String] = [
		"res://stat/_modifier/IQToAttackModifier/IQToAttackModifier.tres",
		
	]
	
	for path in res_paths:
		var res := ResourceLoader.load(path)
		if res:
			register_modifier(res)
	
	for path in basic_res_paths:
		var res := ResourceLoader.load(path)
		if res:
			register_modifier(res)
			basic_modifiers.append(res)

func register_modifier(mod: StatModifier) -> void:
	if mod.id in modifiers:
		push_warning("Duplicate mod id: %s" % mod.id)
		
	modifiers[mod.id] = mod

func get_modifier(id: String) -> StatModifier:
	if modifiers.has(id):
		return modifiers[id]
		
	push_error("Modifier not found by %s" % id)
	return null

func get_random_modifier() -> Resource:
	return basic_modifiers[randi() % len(basic_modifiers)]
